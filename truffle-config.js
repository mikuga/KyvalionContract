module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: "52.199.55.205",
      gasPrice : 1,
      port: 4444,
      from: "0xce4166650a8b9cd871dad41c19417fce2bda4a09",
      network_id: "*"
    }
  }
};
