import 'package:go_router/go_router.dart';
import 'package:loginhome1/presentation/screens/add_screen.dart';
import 'package:loginhome1/presentation/screens/home_screen.dart';
import 'package:loginhome1/presentation/screens/login_screen.dart';
import 'package:loginhome1/presentation/screens/bandas_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      name: LoginScreen.name,
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
  name: HomeScreen.name,
  path: '/home',
  builder: (context, state) {
    return HomeScreen();
  },
),

    GoRoute(
      name: BandasScreen.name,
      path: '/bandas',
      builder: (context, state) => BandasScreen(),
    ),
    GoRoute(
     name: AddScreen.name,
     path: '/add_band_screen',
     builder: (context, state) => const AddScreen(), 
    )
  ],
);
