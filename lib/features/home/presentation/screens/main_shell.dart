import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme.dart';
import '../../../cart/bloc/cart_bloc.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../catalog/presentation/screens/catalog_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../wishlist/presentation/screens/wishlist_screen.dart';

/// Bottom-nav shell. Houses Home, Catalog, Cart, Wishlist, Profile.
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    // Refresh cart count whenever the shell is rebuilt.
    context.read<CartBloc>().add(const CartLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          CatalogScreen(),
          CartScreen(),
          WishlistScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        buildWhen: (p, c) => p.cart.itemCount != c.cart.itemCount,
        builder: (context, state) {
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.primary),
                label: 'Beranda',
              ),
              const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view, color: AppColors.primary),
                label: 'Katalog',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: state.cart.itemCount > 0,
                  label: Text('${state.cart.itemCount}'),
                  backgroundColor: AppColors.error,
                  textColor: Colors.white,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: state.cart.itemCount > 0,
                  label: Text('${state.cart.itemCount}'),
                  backgroundColor: AppColors.error,
                  textColor: Colors.white,
                  child: const Icon(
                    Icons.shopping_cart,
                    color: AppColors.primary,
                  ),
                ),
                label: 'Keranjang',
              ),
              const NavigationDestination(
                icon: Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite, color: AppColors.primary),
                label: 'Wishlist',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.primary),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}
