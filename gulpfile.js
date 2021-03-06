var gulp = require('gulp');
var runSequence = require('run-sequence');
var coffee = require('gulp-coffee');
var gutil = require('gulp-util');
var bump = require('gulp-bump');
var gutil = require('gulp-util');
var git = require('gulp-git');
var fs = require('fs');
var spawn = require('child_process').spawn;
var rimraf = require('rimraf');

function getVersion() {
  // We parse the json file instead of using require because require caches
  // multiple calls so the version number won't be updated
  return JSON.parse(fs.readFileSync('./package.json', 'utf8')).version;
};

gulp.task('default', function(done) {
  runSequence('coffee', 'coffee-watch', done);
});

gulp.task('coffee-watch', function(done) {
  var watcher = gulp.watch('./src/**/*', ['coffee']);
  watcher.on('change', function(event) {
    console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
  });
});

gulp.task('coffee', function(done) {
  rimraf('./lib', function() {
    gulp.src('./src/**/*')
      .pipe(coffee({bare: true}).on('error', gutil.log))
      .pipe(gulp.dest('./lib/'));

    done()
  });
});

gulp.task('bump', function () {
  return gulp.src(['./package.json'])
    .pipe(bump({type: "patch"}).on('error', gutil.log))
    .pipe(gulp.dest('./'));
});

gulp.task('commit', function () {
  return gulp.src('.')
    .pipe(git.add())
    .pipe(git.commit('v' + getVersion()));
});

gulp.task('push', function (done) {
  git.push('origin', 'master', done);
});

gulp.task('tag', function (done) {
  git.tag('v' + getVersion(), 'Created Tag for version: ' + getVersion(), function (error) {
    if (error) {
      return done(error);
    }
    git.push('origin', 'master', {args: '--tags'}, done);
  });
});

gulp.task('publish', function (done) {
  spawn('npm', ['publish'], { stdio: 'inherit' }).on('close', done);
});

gulp.task('release', function(done) {
  runSequence(
    'coffee',
    'bump',
    'commit',
    'push',
    'tag',
    'publish',
    done
  )
});

