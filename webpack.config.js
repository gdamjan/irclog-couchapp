const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');

const outputDir = __dirname + '/dist';

const config = {
  context: __dirname,
  devtool: 'source-map',
  entry: {
    app: './webapp/app.ts',
    vendors: [
      'react',
      'react-dom',
      'react-router',
    ]
  },
  output: {
    path: outputDir,
    filename: 'js/[name].js',
    chunkFilename: 'js/[name].js'
  },
  module: {
    rules: [{
      test: /\.tsx?$/,
      loader: 'ts-loader',
      exclude: /node_modules/,
    }]
  },
  resolve: {
    extensions: [".tsx", ".ts", ".js"]
  },
  plugins: [
    new webpack.optimize.CommonsChunkPlugin({
      name: 'vendors',
      filename: 'js/vendors.js',
      minChunks: Infinity
    }),
    new HtmlWebpackPlugin({template:'./webapp/app.ejs'})
  ]
}

module.exports = config;
