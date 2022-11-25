import 'package:flutter/material.dart';
import '../providers/products.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatelessWidget {
  static const routeName = '/product-detail';

  @override
  Widget build(BuildContext context) {
    final mediaquery = MediaQuery.of(context);
    final productId = ModalRoute.of(context)!.settings.arguments as String;
    final loadedProduct = Provider.of<Products>(context, listen: false).findById(
        productId); //listen:false doesn't build the widget again if product is added or changed

    var height = (mediaquery.size.height - mediaquery.padding.top) * .3;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: height,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(loadedProduct.title),
                background: Hero(
                  tag: productId,
                  child: Image.network(
                    loadedProduct.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 10),
                  Text(
                    'Rs.${loadedProduct.price}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    width: double.infinity,
                    child: Text(
                      loadedProduct.description,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                  SizedBox(
                    height: 900,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
