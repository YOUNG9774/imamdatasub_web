import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/beneficiary_local_datasource.dart';
import '../../data/datasources/buy_data_remote_datasource.dart';
import '../../data/repositories/buy_data_repository_impl.dart';
import '../../domain/entities/beneficiary_entity.dart';
import '../../domain/entities/data_plan_entity.dart';
import '../../domain/repositories/buy_data_repository.dart';

// ── Data layer ─────────────────────────────────────────────
final buyDataRemoteDataSourceProvider =
    Provider<BuyDataRemoteDataSource>((ref) {
  return BuyDataRemoteDataSourceImpl(ref.read(dioClientProvider));
});

final beneficiaryLocalDataSourceProvider =
    Provider<BeneficiaryLocalDataSource>((ref) {
  return BeneficiaryLocalDataSourceImpl(ref.read(hiveStorageProvider));
});

final buyDataRepositoryProvider = Provider<BuyDataRepository>((ref) {
  return BuyDataRepositoryImpl(
    remote: ref.read(buyDataRemoteDataSourceProvider),
    beneficiaryLocal: ref.read(beneficiaryLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
    hive: ref.read(hiveStorageProvider),
  );
});

// ── Selected network state (persists across plan reload) ──
final selectedNetworkProvider =
    StateProvider.autoDispose<NetworkProvider>((ref) => NetworkProvider.mtn);

// ── Data plans for selected network ────────────────────────
final dataPlansProvider = FutureProvider.autoDispose
    .family<List<DataPlanEntity>, NetworkProvider>((ref, network) async {
  final repository = ref.read(buyDataRepositoryProvider);
  final result = await repository.getDataPlans(network);
  return result.fold(
    (failure) => throw failure,
    (plans) => plans,
  );
});

// ── Beneficiaries for data ─────────────────────────────────
final dataBeneficiariesProvider =
    FutureProvider.autoDispose<List<BeneficiaryEntity>>((ref) async {
  final repository = ref.read(buyDataRepositoryProvider);
  return repository.getBeneficiaries();
});

// ── Purchase flow state ────────────────────────────────────
class BuyDataState {
  const BuyDataState({
    this.selectedPlan,
    this.phone = '',
    this.saveAsBeneficiary = false,
    this.isProcessing = false,
    this.errorMessage,
  });

  final DataPlanEntity? selectedPlan;
  final String phone;
  final bool saveAsBeneficiary;
  final bool isProcessing;
  final String? errorMessage;

  bool get canProceed => selectedPlan != null && phone.length == 11;

  BuyDataState copyWith({
    DataPlanEntity? selectedPlan,
    String? phone,
    bool? saveAsBeneficiary,
    bool? isProcessing,
    String? errorMessage,
    bool clearError = false,
    bool clearPlan = false,
  }) {
    return BuyDataState(
      selectedPlan: clearPlan ? null : (selectedPlan ?? this.selectedPlan),
      phone: phone ?? this.phone,
      saveAsBeneficiary: saveAsBeneficiary ?? this.saveAsBeneficiary,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BuyDataNotifier extends StateNotifier<BuyDataState> {
  BuyDataNotifier(this._ref) : super(const BuyDataState());

  final Ref _ref;

  void selectPlan(DataPlanEntity plan) {
    state = state.copyWith(selectedPlan: plan, clearError: true);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone, clearError: true);
  }

  void toggleSaveBeneficiary(bool value) {
    state = state.copyWith(saveAsBeneficiary: value);
  }

  void reset() {
    state = const BuyDataState();
  }

  Future<DataPurchaseResult?> purchase(NetworkProvider network) async {
    if (!state.canProceed) return null;
    state = state.copyWith(isProcessing: true, clearError: true);

    final repository = _ref.read(buyDataRepositoryProvider);
    final result = await repository.purchaseData(
      network: network,
      plan: state.selectedPlan!,
      phone: state.phone,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isProcessing: false, errorMessage: failure.message);
        return null;
      },
      (purchaseResult) async {
        if (purchaseResult.success && state.saveAsBeneficiary) {
          await repository.saveBeneficiary(
            phone: state.phone,
            label: state.phone,
            network: network,
          );
        }
        state = state.copyWith(isProcessing: false);
        return purchaseResult;
      },
    );
  }
}

final buyDataNotifierProvider =
    StateNotifierProvider.autoDispose<BuyDataNotifier, BuyDataState>((ref) {
  return BuyDataNotifier(ref);
});
