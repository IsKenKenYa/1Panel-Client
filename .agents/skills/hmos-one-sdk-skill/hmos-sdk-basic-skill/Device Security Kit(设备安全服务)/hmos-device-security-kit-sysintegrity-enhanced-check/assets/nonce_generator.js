const crypto = require('crypto');

class NonceGenerator {
  static generateNonce(length = null) {
    if (length === null) {
      length = Math.floor(Math.random() * 50) + 16;
    }
    
    if (length < 16 || length > 66) {
      throw new Error('Nonce length must be between 16 and 66 bytes');
    }
    
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let nonce = '';
    
    const bytes = crypto.randomBytes(length);
    for (let i = 0; i < length; i++) {
      nonce += chars[bytes[i] % chars.length];
    }
    
    return nonce;
  }
  
  static validateNonce(nonce) {
    if (typeof nonce !== 'string') {
      return { valid: false, error: 'Nonce must be a string' };
    }
    
    const length = nonce.length;
    if (length < 16 || length > 66) {
      return { valid: false, error: `Nonce length ${length} is out of range (16-66)` };
    }
    
    const validChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    for (let i = 0; i < nonce.length; i++) {
      if (!validChars.includes(nonce[i])) {
        return { valid: false, error: `Invalid character at position ${i}: ${nonce[i]}` };
      }
    }
    
    return { valid: true };
  }
}

function generateNonceForRequest() {
  const nonce = NonceGenerator.generateNonce();
  const validation = NonceGenerator.validateNonce(nonce);
  
  if (!validation.valid) {
    throw new Error(`Generated nonce is invalid: ${validation.error}`);
  }
  
  console.log(`Generated nonce: ${nonce}`);
  console.log(`Nonce length: ${nonce.length}`);
  console.log(`Validation: ${JSON.stringify(validation)}`);
  
  return nonce;
}

module.exports = {
  NonceGenerator,
  generateNonceForRequest
};

if (require.main === module) {
  const nonce = generateNonceForRequest();
  console.log(`\nFinal nonce value: ${nonce}`);
}