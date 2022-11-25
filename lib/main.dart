import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';
import '../screens/waiting_screen.dart';
import './screens/orders_screen.dart';
import './screens/user_products_screen.dart';
import './providers/orders.dart';
import './screens/cart_screen.dart';
import './screens/product_detail_screen.dart';
import './screens/products_overview_screen.dart';
import './providers/products.dart';
import './providers/cart.dart';
import './screens/edit_product_screen.dart';
import './screens/auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => Auth(),
        ),
        ChangeNotifierProxyProvider<Auth, Products>(
          create: (ctx) => Products('', '', []),
          update: (ctx, auth, previousProducts) => Products(
            auth.token.toString(),
            auth.userId.toString(),
            previousProducts == null ? [] : previousProducts.items,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Cart(),
        ),
        ChangeNotifierProxyProvider<Auth, Order>(
          create: (ctx) => Order('', '', []),
          update: (ctx, auth, previousOrders) => Order(
            auth.token.toString(),
            auth.userId.toString(),
            previousOrders == null ? [] : previousOrders.orders,
          ),
        ),
      ],
      child: Consumer<Auth>(
        builder: ((context, auth, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Flutter Demo',
              theme: ThemeData(
                primarySwatch: Colors.pink,
                accentColor: Colors.lightGreen,
                fontFamily: 'Lato',
              ),
              home: auth.isAuth
                  ? ProductOverviewScreen()
                  : FutureBuilder(
                      future: auth.tryAutoLogin(),
                      builder: (context, snapshot) =>
                          snapshot.connectionState == ConnectionState.waiting
                              ? const LoadingScreen()
                              : snapshot.data == false
                                  ? AuthScreen()
                                  : ProductOverviewScreen(),
                    ),
              routes: {
                ProductDetailScreen.routeName: (context) =>
                    ProductDetailScreen(),
                CartScreen.routeName: (context) => CartScreen(),
                OrdersScreen.routeName: (context) => const OrdersScreen(),
                UserProductsScreen.routeName: (context) =>
                    const UserProductsScreen(),
                EditProductScreen.routeName: (context) =>
                    const EditProductScreen(),
                AuthScreen.routeName: (context) => AuthScreen(),
              },
            )),
      ),
    );
  }
}
