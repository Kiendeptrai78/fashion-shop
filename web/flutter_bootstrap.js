{{flutter_js}}
{{flutter_build_config}}

const buildVersion = {{flutter_service_worker_version}};
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) build.mainJsPath += "?release=" + buildVersion;
}
_flutter.loader.load({
  serviceWorkerSettings: {serviceWorkerVersion: buildVersion}
});
