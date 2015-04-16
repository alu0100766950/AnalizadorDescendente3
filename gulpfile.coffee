gulp = require('gulp')
shell = require('gulp-shell')
concat = require('gulp-concat')
uglify = require('gulp-uglify')
minifyHTML = require('gulp-minify-html');
minifyCSS = require('gulp-minify-css');


# run coffee server
gulp.task 'cofserver', ->
  gulp.src('').pipe shell([ 'coffee app.coffee' ])

#run tests
gulp.task 'tests', [ 'mocha' ]
gulp.task 'mocha', ->
  gulp.src('').pipe shell(['mocha --compilers coffee:coffee-script/register -R spec'])

#run minify html
gulp.task 'minify-html', ->
  gulp.src('index.html').pipe(concat('minified_index.html')).pipe(minifyHTML()).pipe gulp.dest('minify/html')
