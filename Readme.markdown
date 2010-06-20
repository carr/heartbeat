Heartbeat
=======

Heartbeat is an Ajax based Rails plugin that utilizes pessimistic locking using the heartbeat pattern.

Heartbeat solves the problem when you don't want multiple users editing the same record. It sends a "heartbeat" using AJAX
and notifies the server that the user is editing (using) a specific record. Once the heartbeats stop coming in, the record 
is free to be used by someone else.

Install
=======

To install, run:

    script/plugin install git://github.com/carr/heartbeat.git

Usage
=====

In your model add the fields

    script/generate migration add_last_used_at_and_last_used_by_to_orders last_used_at:datetime last_used_by:integer

Add the following to all models that need heartbeat monitoring:

    has_hartbeat :interval => 5.seconds

You can omit the <tt>interval</tt> parameter, the default is 5.seconds.

In your routes, add a member route for monitoring your resource and one for retrieving the status:

    map.resources :orders, :member => {:heartbeat => :post, :is_used => :get}

Then you need to configure your controller:

Add this to lib/heartbeat_controller.rb

    module HeartbeatController
      def heartbeat_model
        @heartbeat_model = self.class.name.gsub(/Controller$/, '').singularize.constantize    
      end

      def heartbeat
        @heartbeat_record = heartbeat_model.find(params[:id])
        @heartbeat_record.use!(current_user.id)
        render :text => ''
      end

      def is_used
        @heartbeat_record = heartbeat_model.find(params[:id])
        render :text => @heartbeat_record.is_used? ? 'true' : 'false'
      end
    end

And include in all controllers that monitor heartbeats.

    class OrderController < ApplicationController
      include HeartbeatController
    end

You can customize the controller part to fit your specific needs.

Views
=====

To make it all work, you need to add a monitoring part to your views, if you use RJS, something like this will work:

    <% if @order.is_used? %>
      Sorry, the record is being used, come back later.
    <% else %>
      <%= periodically_call_remote(:url => { :action => 'heartbeat', :id => @order.id }, :frequency => Order.heartbeat_interval)  %>
    <% end %>

Model
=====

Calling <tt>has_heartbeat</tt> in a model gives you a couple of new class methods:

    Order.heartbeat_interval  # the interval in which heartbeats occur
    Order.used                # scope on records being used by somebody
    Order.unused              # scope on records not being used by anybody

And a couple of new instance methods:

    @order.use!(user_id)      # marks the record as being used by the user with the specified user_id
    @order.free               # frees up the record
    @order.is_used?           # checks to see if the record is being used by anybody

TODO
====

* The reload problem (if you reload, you get the error that the record is being used, and have to wait for the interval to pass)
* If you don't wan't to wait for the first ajax call to kick in, you need to call <tt>record.use!(..)</tt> yourself in the controller, 
which screws up everything in the view (because <tt>record.is_used?</tt> now returns <tt>true</tt>)

Author
======

Copyright © 2010 Tomislav Car, Infinum, released under the MIT license
