enum AppFlavor { dev, prod }

class Environment {
  static late AppFlavor flavor;

  static bool get isDev => flavor == AppFlavor.dev;
  static bool get isProd => flavor == AppFlavor.prod;

  static void init(AppFlavor f) {
    flavor = f;
  }
}
