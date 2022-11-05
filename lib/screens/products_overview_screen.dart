import 'package:flutter/material.dart';
import '../widgets/products_grid.dart';

class ProductOverviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('sisakala'),
      ),
      body: ProductsGrid(),
    );
  }
}