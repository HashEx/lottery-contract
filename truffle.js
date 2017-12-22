require('babel-register');
require('babel-polyfill');

module.exports = {
  networks: {
    coverage: {
      host: "localhost",
      network_id: "*",
      port: 9545,
      gas: 6000000
    }
  }
};