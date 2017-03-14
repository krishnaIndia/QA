// TODO try to replace with digitalocean.node package from npm

var Api = function(token, testMode) {
  var vultr = require('vultr')(token);

  this.getAvaliableRegions = function(size, callback) {
    vultr.regions.list().then(function(list) {
      // TODO display and then grep
      var regList = [];
      for (var region in list) {
        regList.push(region.DCID + ' - ' + region.name);
      }
      callback(null, regList);
    });
  };

  this.createDroplet = function(name, region, size, image, sshKeys, callback) {
    vultr.server.create({
     'region': parseInt(region.split('-')[0]), // (required) Get the region ID
     'plan': 29, // (required) Get the plan ID
     'os': 215,  // (required) Get the OS ID          
     'snapshot': image, // Get the snapshot ID
     'enable_ipv6': 'no', // 'yes' or 'no' to enable ipv6 (if available)     
     'label': name,
     'sshkey': sshKeys.join(','), // Seperate multiple keys with comma's
     'auto_backups': 'no' // 'yes' or 'no'. If yes, automatic backups will be enabled for this server (these have an extra charge associated with them)
    }).then(function(id) {
      callback(null, id);
    });
  };

  this.getDroplet = function(id, callback) {
    vultr.server.list().then(function(list) {
      for (var server in list) {
        if (server.SUBID === id) {
          server.id = server.SUBID;
          server.name = server.label;
          server.networks = { v4 : [ {ip_address: server.main_ip} ] };
          return callback(null, server);
        }
      }
      callback('Not found');
    });
  };

  this.getDropletList = function(callback) {
    vultr.server.list().then(function(list) {
      var updatedList = [];
      for (var server in list) {
        server.id = server.SUBID;
        server.name = server.label;
        server.networks = { v4 : [ {ip_address: server.main_ip} ] };
        updatedList.push(server);
      }
      callback(null, server);
    });
  };

  this.deleteDroplet = function(id, callback) {
    vultr.server.destroyIpv4(id, 'no'); // To be tested for the usage of proper function
    callback(null);    
  };

  this.getImage = function(id, callback) {
    this.getAvaliableRegions(function(err, regions) {
      callback(null, {image: {regions: regions}});
    });
  };

  return this;
};

exports.Api = Api;
