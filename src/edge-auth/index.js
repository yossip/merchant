'use strict';

const jwt = require('jsonwebtoken'); // Assuming packed with dependencies
const jwksClient = require('jwks-rsa');

// Example: Cognito User Pool
const cognitoIssuer = `https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxxxxxx`;

const client = jwksClient({
  jwksUri: `${cognitoIssuer}/.well-known/jwks.json`,
  cache: true,
  rateLimit: true
});

function getKey(header, callback) {
  client.getSigningKey(header.kid, function(err, key) {
    if (err) {
      return callback(err);
    }
    const signingKey = key.publicKey || key.rsaPublicKey;
    callback(null, signingKey);
  });
}

/**
 * Validates the Authorization header JWT at the edge.
 * Intercepts Viewer Requests before they reach the EKS Origin.
 */
exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  // Paths that do not require authentication (e.g., catalog, login)
  const publicPaths = ['/api/catalog', '/api/public'];
  if (publicPaths.some(path => request.uri.startsWith(path))) {
    return request; // Allow request through
  }

  const authHeader = headers['authorization'];
  if (!authHeader || !authHeader[0].value.startsWith('Bearer ')) {
    return generateUnauthorizedResponse('Missing or invalid Authorization header');
  }

  const token = authHeader[0].value.substring(7);

  try {
    // Wrap jwt.verify in a Promise
    const decoded = await new Promise((resolve, reject) => {
      jwt.verify(token, getKey, { issuer: cognitoIssuer }, (err, decoded) => {
        if (err) return reject(err);
        resolve(decoded);
      });
    });

    // Token is valid. We can optionally attach claims to context for backend use,
    // but typically just letting the request pass is enough. The backend can
    // decode the JWT later for specific authorization logic.
    console.log(`Validated edge request for user: ${decoded.sub}`);
    
    // Proceed to the Origin (EKS ALB)
    return request;
  } catch (err) {
    console.error(`JWT Verification Failed: ${err.message}`);
    return generateUnauthorizedResponse('Invalid Token');
  }
};

function generateUnauthorizedResponse(message) {
  return {
    status: '401',
    statusDescription: 'Unauthorized',
    body: JSON.stringify({ message }),
    headers: {
      'content-type': [{ key: 'Content-Type', value: 'application/json' }],
      'www-authenticate': [{ key: 'WWW-Authenticate', value: 'Bearer' }]
    }
  };
}
