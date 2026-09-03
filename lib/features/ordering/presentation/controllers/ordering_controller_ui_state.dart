import '../../models/product.dart';
import 'ordering_controller.dart';

class _OrderingUiState {
  String? selectedCategory;
  int carouselIndex = 0;
}

final Expando<_OrderingUiState> _uiState = Expando<_OrderingUiState>();

_OrderingUiState _stateFor(OrderingController controller) =>
    _uiState[controller] ??= _OrderingUiState();

extension OrderingControllerUiState on OrderingController {
  String? get selectedCategory => _stateFor(this).selectedCategory;

  List<Product> get filteredProducts => selectedCategory == null
      ? products
      : products.where((product) => product.category == selectedCategory).toList();

  void setCategory(String? category) {
    final state = _stateFor(this);
    state.selectedCategory = category;
    state.carouselIndex = 0;
    notifyListeners();
  }

  void enterCategory(String category) {
    setCategory(category);
  }

  int get carouselIndex {
    final state = _stateFor(this);
    if (products.isEmpty) return 0;
    if (state.carouselIndex >= products.length) {
      state.carouselIndex = products.length - 1;
    }
    return state.carouselIndex;
  }

  void setCarouselIndex(int index) {
    final state = _stateFor(this);
    state.carouselIndex = products.isEmpty
        ? 0
        : index.clamp(0, products.length - 1);
    notifyListeners();
  }
}
