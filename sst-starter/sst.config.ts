/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
  app(input) {
    return {
      name: "sst-starter",
      removal: input?.stage === "production" ? "retain" : "remove",
      home: "aws",
    };
  },
  async run() {
    const api = new sst.aws.Function("MyApi", {
      handler: "src/index.handler",
      url: true,
    });

    return {
      api: api.url,
    };
  },
});
