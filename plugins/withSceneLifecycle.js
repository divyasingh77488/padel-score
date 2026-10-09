// iOS 27 refuses to launch apps built with the iOS 27 SDK unless they use the scene-based
// life cycle. Expo SDK 57 ships the scene delegate (`ExpoAppSceneDelegate`) but its prebuild
// template doesn't use it yet; SDK 58's template does. This plugin applies the SDK 58 changes:
// - Info.plist: register Expo's scene delegate.
// - AppDelegate: conform to `ExpoReactNativeFactoryProvider` and stop creating the window,
//   since the scene delegate now creates it and starts React Native.
// Remove this plugin after upgrading to an Expo SDK whose template adopts scenes.
const { withAppDelegate, withInfoPlist } = require('expo/config-plugins');

const WINDOW_SETUP = `#if os(iOS) || os(tvOS)
    window = UIWindow(frame: UIScreen.main.bounds)
    factory.startReactNative(
      withModuleName: "main",
      in: window,
      launchOptions: launchOptions)
#endif
`;

function withSceneLifecycle(config) {
  config = withInfoPlist(config, (cfg) => {
    cfg.modResults.UIApplicationSceneManifest = {
      UIApplicationSupportsMultipleScenes: false,
      UISceneConfigurations: {
        UIWindowSceneSessionRoleApplication: [
          {
            UISceneConfigurationName: 'Default Configuration',
            UISceneDelegateClassName: 'EXExpoAppSceneDelegate',
          },
        ],
      },
    };
    return cfg;
  });

  return withAppDelegate(config, (cfg) => {
    let src = cfg.modResults.contents;
    if (!src.includes('ExpoReactNativeFactoryProvider')) {
      const before = src;
      src = src.replace(
        'class AppDelegate: ExpoAppDelegate {',
        'class AppDelegate: ExpoAppDelegate, ExpoReactNativeFactoryProvider {',
      );
      src = src.replace(WINDOW_SETUP, '');
      if (src === before || src.includes('window = UIWindow(frame:')) {
        throw new Error(
          'withSceneLifecycle: AppDelegate.swift does not match the Expo SDK 57 template; ' +
            'update plugins/withSceneLifecycle.js.',
        );
      }
    }
    cfg.modResults.contents = src;
    return cfg;
  });
}

module.exports = withSceneLifecycle;
