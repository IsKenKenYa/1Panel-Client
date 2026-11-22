import json
import base64
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.serialization import load_pem_public_key
from cryptography.exceptions import InvalidSignature

class ServerVerify:
    def __init__(self, public_key_pem: str):
        self.public_key = load_pem_public_key(public_key_pem.encode())

    def verify_jws(self, jws: str) -> dict:
        parts = jws.split('.')
        if len(parts) != 3:
            raise ValueError('Invalid JWS format')

        header_b64, payload_b64, signature_b64 = parts

        header = self._base64_decode(header_b64)
        header_dict = json.loads(header)

        if header_dict.get('alg') != 'RS256':
            raise ValueError(f'Unsupported algorithm: {header_dict.get("alg")}')

        payload = self._base64_decode(payload_b64)
        payload_dict = json.loads(payload)

        is_valid = self._verify_signature(header_b64, payload_b64, signature_b64)
        if not is_valid:
            raise ValueError('JWS signature verification failed')

        return payload_dict

    def _base64_decode(self, data: str) -> str:
        missing_padding = len(data) % 4
        if missing_padding:
            data += '=' * (4 - missing_padding)
        
        decoded_bytes = base64.urlsafe_b64decode(data)
        return decoded_bytes.decode('utf-8')

    def _verify_signature(self, header: str, payload: str, signature: str) -> bool:
        signing_input = f'{header}.{payload}'
        signature_bytes = base64.urlsafe_b64decode(signature + '===')

        try:
            self.public_key.verify(
                signature_bytes,
                signing_input.encode(),
                padding.PKCS1v15(),
                hashes.SHA256()
            )
            return True
        except InvalidSignature:
            return False

    def verify_purchase_order(self, jws_purchase_order: str) -> dict:
        return self.verify_jws(jws_purchase_order)

    def check_purchase_valid(self, purchase_order: dict) -> bool:
        if purchase_order.get('purchaseOrderRevocationReasonCode'):
            return False
        
        if purchase_order.get('finishStatus') == '2':
            return False
        
        return True

def verify_purchase_from_client(jws_purchase_order: str, public_key_path: str) -> dict:
    with open(public_key_path, 'r') as f:
        public_key_pem = f.read()
    
    verifier = ServerVerify(public_key_pem)
    purchase_order = verifier.verify_purchase_order(jws_purchase_order)
    
    if not verifier.check_purchase_valid(purchase_order):
        raise ValueError('Purchase order is revoked or invalid')
    
    return purchase_order

if __name__ == '__main__':
    example_public_key = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArN3p...
-----END PUBLIC KEY-----
'''
    
    example_jws = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJwdXJjaGFzZU9yZGVySWQiOiJvcmRlcl94eHgiLCJwdXJjaGFzZVRva2VuIjoidG9rZW5feHh4IiwicHJvZHVjdFR5cGUiOjMsInByb2R1Y3RJZCI6Im9ob3Nfbm9ucmVuZXdhYmxlXzAwMSIsInB1cmNoYXNlVGltZSI6MTcwNDA2NzIwMDAwMCwicHJpY2UiOjEwMDAsImN1cnJlbmN5IjoiQ05ZIn0.signature'
    
    verifier = ServerVerify(example_public_key)
    try:
        purchase_order = verifier.verify_purchase_order(example_jws)
        print('Purchase order verified successfully:')
        print(json.dumps(purchase_order, indent=2))
    except Exception as e:
        print(f'Verification failed: {e}')