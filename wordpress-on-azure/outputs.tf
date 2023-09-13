
output "lb_ip" {
  value = azurerm_public_ip.jcassanji-tf-lb-publicip.id
}

output "database_username" {
  value     = azurerm_mssql_server.jcassanji-tf-sqlserver.administrator_login
 
}

output "database_password" {
  value     = azurerm_mssql_server.jcassanji-tf-sqlserver.administrator_login_password
  sensitive = true
}