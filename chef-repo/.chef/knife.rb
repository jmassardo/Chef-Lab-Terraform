# See https://docs.getchef.com/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "labadmin"
client_key               "#{current_dir}/labadmin.pem"
chef_server_url          "https://chef.lab.local/organizations/lab"
cookbook_path            ["#{current_dir}/../cookbooks"]
ssl_verify_mode          :verify_none
