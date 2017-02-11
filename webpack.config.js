const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');

const outputDir = __dirname + '/dist';
const srcDir = __dirname + '/webapp';

const config = {
  context: srcDir,
  devtool: 'source-map',

  entry: {
    app: './app.ts',
    vendors: ['react','react-dom','react-router']
  },

  output: {
    path: outputDir,
    filename: 'js/[name].js',
    chunkFilename: 'js/[name].js'
  },

  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/
      },
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          fallback: 'style-loader',
          use: 'css-loader'
        })
      }
    ]
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js']
  },

  plugins: [
    new webpack.optimize.CommonsChunkPlugin({
      name: 'vendors',
      filename: 'js/vendors.js',
      minChunks: Infinity
    }),
    new ExtractTextPlugin({
      filename: 'css/app.css',
      allChunks: true,
    }),
    new HtmlWebpackPlugin({template:'./app.html'})
  ],
  bail: true
}

module.exports = config;
