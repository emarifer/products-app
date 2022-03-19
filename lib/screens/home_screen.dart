import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../screens/screens.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductsService productsServices =
        Provider.of<ProductsService>(context);

    final AuthService authService =
        Provider.of<AuthService>(context, listen: false);

    if (productsServices.isLoading) return const LoadingScreen();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        leading: IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () {
            authService.logout();
            Navigator.pushReplacementNamed(context, 'login');
          },
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: productsServices.products.length,
        itemBuilder: (BuildContext context, int index) => GestureDetector(
          child: ProductCard(product: productsServices.products[index]),
          onTap: () {
            // Hay que romper la referencia para que no impactemos
            // en la lista productsService.product.
            // Usamoa para ello el metodo copy(), que hemos creado en el servicio
            productsServices.selectedProduct =
                productsServices.products[index].copy();
            Navigator.pushNamed(context, 'product');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          productsServices.selectedProduct = Product(
            available: false,
            name: '',
            price: 0,
          );

          Navigator.pushNamed(context, 'product');
        },
      ),
    );
  }
}
