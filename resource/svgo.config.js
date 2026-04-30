module.exports = {
  multipass: true,
  plugins: [
    'removeDoctype',
    'removeComments',
    'removeMetadata',
    'removeTitle',
    'removeDesc',
    'cleanupAttrs',
    'mergePaths',
    'convertStyleToAttrs'
  ]
};
