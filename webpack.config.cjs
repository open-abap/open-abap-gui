const path = require("node:path");
const webpack = require("webpack");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const HtmlInlineScriptPlugin = require("html-inline-script-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");

module.exports = {
  mode: "production",
  target: "web",
  entry: path.resolve(__dirname, "web/web.mjs"),
  output: {
    path: path.resolve(__dirname, "build"),
    filename: "web.js",
    clean: true,
  },
  devtool: false,
  optimization: {
    minimize: true,
    minimizer: [
      new TerserPlugin({
        extractComments: false,
        terserOptions: {
          keep_classnames: true,
          keep_fnames: true,
          mangle: {
            keep_classnames: true,
            keep_fnames: true,
          },
        },
      }),
    ],
  },
  resolve: {
    extensions: [".mjs", ".js"],
    // The browser build must not fetch sql-wasm.wasm: the final artifact is
    // deliberately one self-contained HTML file.
    alias: {
      "sql.js$": path.resolve(__dirname, "node_modules/sql.js/dist/sql-asm.js"),
    },
    fallback: {
      assert: require.resolve("assert/"),
      buffer: require.resolve("buffer/"),
      crypto: require.resolve("crypto-browserify"),
      constants: require.resolve("constants-browserify"),
      events: require.resolve("events/"),
      fs: false,
      http: require.resolve("stream-http"),
      https: require.resolve("https-browserify"),
      os: require.resolve("os-browserify/browser"),
      path: require.resolve("path-browserify"),
      process: require.resolve("process/browser"),
      stream: require.resolve("stream-browserify"),
      string_decoder: require.resolve("string_decoder/"),
      util: require.resolve("util/"),
      url: require.resolve("url/"),
      vm: require.resolve("vm-browserify"),
      zlib: require.resolve("browserify-zlib"),
      net: false,
      tls: false,
    },
  },
  module: {
    rules: [
      {
        test: /\.m?js$/,
        resolve: {fullySpecified: false},
      },
    ],
  },
  plugins: [
    new webpack.NormalModuleReplacementPlugin(
      /%23ui2%23cl_json\.clas(?:\.locals)?\.mjs$/,
      (resource) => {
        const filename = resource.request.replace(/^\.\//, "").replaceAll(
          "%23ui2%23",
          "#ui2#",
        );
        resource.request = path.resolve(__dirname, "output", filename);
      },
    ),
    new webpack.ProvidePlugin({
      Buffer: ["buffer", "Buffer"],
      process: "process/browser",
    }),
    new HtmlWebpackPlugin({
      template: path.resolve(__dirname, "web/index.html"),
      filename: "index.html",
      inject: "body",
      scriptLoading: "blocking",
      minify: false,
    }),
    // Inline the complete entry asset and remove it from the output directory.
    new HtmlInlineScriptPlugin(),
    // The transpiler emits dynamic imports for generated ABAP modules. Keep
    // those modules in the same asset so the inline-script plugin can produce
    // one HTML file.
    new webpack.optimize.LimitChunkCountPlugin({maxChunks: 1}),
  ],
};
