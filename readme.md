[![Build Status](https://secure.travis-ci.org/arsduo/koala.png)](http://travis-ci.org/arsduo/koala)

Koala
====
[Koala](http://github.com/arsduo/koala) is a Facebook library for Ruby, supporting the Graph API (including the batch requests and photo uploads), the REST API, realtime updates, test users, and OAuth validation.  We wrote Koala with four goals:

* Lightweight: Koala should be as light and simple as Facebook’s own libraries, providing API accessors and returning simple JSON.
* Fast: Koala should, out of the box, be quick. Out of the box, we use Facebook's faster read-only servers when possible and if available, the Typhoeus gem to make snappy Facebook requests.  Of course, that brings us to our next topic:
* Flexible: Koala should be useful to everyone, regardless of their current configuration.  (We support JRuby, Rubinius, and REE as well as vanilla Ruby, and use the Faraday library to provide complete flexibility over how HTTP requests are made.)
* Tested: Koala should have complete test coverage, so you can rely on it.  (Our test coverage is complete and can be run against either mocked responses or the live Facebook servers.)

Installation
---

Easy:

    [sudo|rvm] gem install koala --pre # for 1.2 beta
    [sudo|rvm] gem install koala # for 1.1

Or in Bundler:

    gem "koala", "~> 1.2.0beta" 
    gem "koala" # for 1.1 

Graph API
----
The Graph API is the simple, slick new interface to Facebook's data.  Using it with Koala is quite straightforward:

    @graph = Koala::Facebook::API.new(oauth_access_token)
    profile = @graph.get_object("me")
    friends = @graph.get_connections("me", "friends")
    @graph.put_object("me", "feed", :message => "I am writing on my wall!")

The response of most requests is the JSON data returned from the Facebook servers as a Hash.

When retrieving data that returns an array of results (for example, when calling API#get_connections or API#search) a GraphCollection object will be returned, which makes it easy to page through the results:

    # Returns the feed items for the currently logged-in user as a GraphCollection
    feed = @graph.get_connections("me", "feed")
    feed.each {|f| do_something_with_item(f) } # it's a subclass of Array
    next_feed = feed.next_page

    # You can also get an array describing the URL for the next page: [path, arguments]
    # This is useful for storing page state across multiple browser requests
    next_page_params = feed.next_page_params
    page = @graph.get_page(next_page_params)

You can also make multiple calls at once using Facebook's batch API:

    # Returns an array of results as if they were called non-batch
    @graph.batch do |batch_api|
      batch_api.get_object('me')
      batch_api.put_wall_post('Making a post in a batch.')
    end

Check out the wiki for more details and examples.

The REST API
-----
Where the Graph API and the old REST API overlap, you should choose the Graph API.  Unfortunately, that overlap is far from complete, and there are many important API calls that can't yet be done via the Graph.

Fortunately, Koala supports the REST API using the very same interface; to use this, instantiate an API:

  	@rest = Koala::Facebook::API.new(oauth_access_token)
  	@rest.fql_query(my_fql_query) # convenience method
  	@rest.fql_multiquery(fql_query_hash) # convenience method
  	@rest.rest_call("stream.publish", arguments_hash) # generic version

Of course, you can use the Graph API methods on the same object -- the power of two APIs right in the palm of your hand.

    @api = Koala::Facebook::API.new(oauth_access_token)
    fql = @api.fql_query(my_fql_query)
    @api.put_wall_post(process_result(fql))
    

OAuth
-----
You can use the Graph and REST APIs without an OAuth access token, but the real magic happens when you provide Facebook an OAuth token to prove you're authenticated.  Koala provides an OAuth class to make that process easy:
    @oauth = Koala::Facebook::OAuth.new(app_id, app_secret, callback_url)

If your application uses Koala and the Facebook [JavaScript SDK](http://github.com/facebook/connect-js) (formerly Facebook Connect), you can use the OAuth class to parse the cookies:
    @oauth.get_user_from_cookies(cookies) # gets the user's ID
	  @oauth.get_user_info_from_cookies(cookies) # parses and returns the entire hash

And if you have to use the more complicated [redirect-based OAuth process](http://developers.facebook.com/docs/authentication/), Koala helps out there, too:
	  # generate authenticating URL
	  @oauth.url_for_oauth_code
	  # fetch the access token once you have the code
	  @oauth.get_access_token(code)

You can also get your application's own access token, which can be used without a user session for subscriptions and certain other requests:
    @oauth.get_app_access_token

For those building apps on Facebook, parsing signed requests is simple:
    @oauth.parse_signed_request(request)

Or, if for some horrible reason, you're still using session keys, despair not!  It's easy to turn them into shiny, modern OAuth tokens:
    @oauth.get_token_from_session_key(session_key)
    @oauth.get_tokens_from_session_keys(array_of_session_keys)

That's it!  It's pretty simple once you get the hang of it.  If you're new to OAuth, though, check out the wiki and the OAuth Playground example site (see below).

Real-time Updates
-----
Sometimes, reaching out to Facebook is a pain -- let it reach out to you instead.  The Graph API allows your application to subscribe to real-time updates for certain objects in the graph; check the [official Facebook documentation](http://developers.facebook.com/docs/api/realtime) for more details on what objects you can subscribe to and what limitations may apply.

Koala makes it easy to interact with your applications using the RealtimeUpdates class:

    @updates = Koala::Facebook::RealtimeUpdates.new(:app_id => app_id, :secret => secret)

You can do just about anything with your real-time update subscriptions using the RealtimeUpdates class:

    # Add/modify a subscription to updates for when the first_name or last_name fields of any of your users is changed
    @updates.subscribe("user", "first_name, last_name", callback_token, verify_token)

    # Get an array of your current subscriptions (one hash for each object you've subscribed to)
    @updates.list_subscriptions

    # Unsubscribe from updates for an object
    @updates.unsubscribe("user")

And to top it all off, RealtimeUpdates provides a static method to respond to Facebook servers' verification of your callback URLs:

    # Returns the hub.challenge parameter in params if the verify token in params matches verify_token
    Koala::Facebook::RealtimeUpdates.meet_challenge(params, your_verify_token)

For more information about meet_challenge and the RealtimeUpdates class, check out the Real-Time Updates page on the wiki.

Test Users
-----

We also support the test users API, allowing you to conjure up fake users and command them to do your bidding using the Graph or REST API:

    @test_users = Koala::Facebook::TestUsers.new(:app_id => id, :secret => secret)
    user = @test_users.create(is_app_installed, desired_permissions)
    user_graph_api = Koala::Facebook::API.new(user["access_token"])
    # or, if you want to make a whole community:
    @test_users.create_network(network_size, is_app_installed, common_permissions)

See examples, ask questions
-----
Some resources to help you as you play with Koala and the Graph API:

* Complete Koala documentation <a href="http://wiki.github.com/arsduo/koala/">on the wiki</a>
* The <a href="http://groups.google.com/group/koala-users">Koala users group</a> on Google Groups, the place for your Koala and API questions
* The Koala-powered <a href="http://oauth.twoalex.com" target="_blank">OAuth Playground</a>, where you can easily generate OAuth access tokens and any other data needed to test out the APIs or OAuth

Testing
-----

Unit tests are provided for all of Koala's methods.  By default, these tests run against mock responses and hence are ready out of the box:

    # From anywhere in the project directory:
    bundle exec rake spec


You can also run live tests against Facebook's servers:

    # Again from anywhere in the project directory:
    LIVE=true bundle exec rake spec

By default, the live tests are run against test users, so you can run them as frequently as you want.  If you want to run them against a real user, however, you can fill in the OAuth token, code, and access\_token values in spec/fixtures/facebook_data.yml.  See the wiki for more details.