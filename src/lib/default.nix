{
  useApi = api: config: builtins.elem api config.api;
  useCore = core: config: config.core == core;
}
