const mysql = require("mysql2");

const connection = mysql.createConnection({
  host: "127.0.0.1",
  user: "root",
  password: "your_mysql_password",
  database: "skr_bdaybot"
});

connection.connect(err => console.log(err ? err : "Connected!"));
