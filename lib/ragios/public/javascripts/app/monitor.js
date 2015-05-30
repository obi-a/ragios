var Monitor = Backbone.Model.extend({
  idAttribute: '_id'
});

var Monitors = Backbone.Collection.extend({
  model: Monitor,
  url: '/monitors'
});


