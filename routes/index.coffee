express = require('express')
router = express.Router()

### GET home page. ###

router.get '/', (req, res, next) ->
  res.render 'index', title: 'Express'
  return
module.exports =
  index: (req, res) ->
    res.render 'index',
      title: 'My Coffeepress Blog'
      posts: []
      
  newPost: (req, res) ->
    res.render 'add_post', title:"Write New Post"
