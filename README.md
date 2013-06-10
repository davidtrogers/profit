# Profit (Profile It)

![Step 3](http://thetrichordist.files.wordpress.com/2013/05/gnomes_plan.png)

Profit is a client/server pair that lets you record timing data for your code.

Here's the client
``` ruby
# my_ruby_app.rb
client = Profit::Client.new
client.start("some_suspect_code")
some_thing_is_not_right
client.stop("some_suspect_code")
```

Here's the server
``` shell
$ profit_server --redis-address 127.0.0.1:6379 \
                --zmq-address tcp://*:5556 \
                --pool-size 10
```

And if you looked in Redis
``` ruby
irb(main):001:0>Redis.new(host: "127.0.0.1", port: 6379).lrange("some_foo_measurement", 0, -1)
=> ["{\"recorded_time\":1.001161,\"start_file\":\"/Users/me/dev/my_ruby_app.rb\",\"start_line\":27,\"stop_file\":\"/Users/me/dev/my_ruby_app.rb\",\"stop_line\":27}"]
```

With this, you could track the data over time, see how some optimizations change the performance at runtime, make pretty graphs, you name it!
