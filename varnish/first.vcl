vcl 4.1;

backend default{
    .host = "httpd";
    .port = "80";
}
 sub vcl_deliver {
      set resp.http.hello = "Hello, World";
   }