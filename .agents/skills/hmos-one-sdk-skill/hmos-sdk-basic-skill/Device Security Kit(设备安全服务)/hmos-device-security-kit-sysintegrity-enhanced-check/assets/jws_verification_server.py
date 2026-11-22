import base64
import json
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509 import load_pem_x509_certificate
import requests

class JWSVerifier:
    ROOT_CA_URL = "https://pki.consumer.huawei.com/ca/cer/Huawei_CBG_ECC_Device_Attestation_Root_CA.cer"
    EXPECTED_CN = "Harmony OS Device Attestation Service"
    
    def __init__(self):
        self.root_ca = self._load_root_ca()
    
    def _load_root_ca(self):
        response = requests.get(self.ROOT_CA_URL)
        if response.status_code != 200:
            raise Exception("Failed to download Root CA certificate")
        return load_pem_x509_certificate(response.content, default_backend())
    
    def verify_jws(self, jws: str, expected_nonce: str, expected_bundle_name: str, expected_app_id: str) -> dict:
        parts = jws.split('.')
        if len(parts) != 3:
            raise ValueError("Invalid JWS format: must have 3 parts")
        
        header = self._decode_base64url(parts[0])
        payload = self._decode_base64url(parts[1])
        signature = parts[2]
        
        header_dict = json.loads(header)
        payload_dict = json.loads(payload)
        
        self._verify_cert_chain(header_dict['x5c'])
        self._verify_signature(parts[0] + '.' + parts[1], signature, header_dict['x5c'][0])
        self._verify_payload(payload_dict, expected_nonce, expected_bundle_name, expected_app_id)
        
        return {
            'verified': True,
            'basic_integrity': payload_dict.get('basicIntegrity', False),
            'detail': payload_dict.get('detail', []),
            'timestamp': payload_dict.get('timestamp'),
            'nonce': payload_dict.get('nonce'),
            'version': payload_dict.get('version')
        }
    
    def _decode_base64url(self, data: str) -> str:
        missing_padding = len(data) % 4
        if missing_padding:
            data += '=' * (4 - missing_padding)
        return base64.urlsafe_b64decode(data).decode('utf-8')
    
    def _verify_cert_chain(self, x5c: list):
        if len(x5c) != 3:
            raise ValueError("Certificate chain must have 3 certificates")
        
        cert0_pem = self._base64_to_pem(x5c[0])
        cert0 = load_pem_x509_certificate(cert0_pem.encode(), default_backend())
        
        cn = cert0.subject.get_attributes_for_oid(x509.NameOID.COMMON_NAME)[0].value
        if cn != self.EXPECTED_CN:
            raise ValueError(f"Certificate CN mismatch: expected {self.EXPECTED_CN}, got {cn}")
        
        cert1_pem = self._base64_to_pem(x5c[1])
        cert1 = load_pem_x509_certificate(cert1_pem.encode(), default_backend())
        
        cert2_pem = self._base64_to_pem(x5c[2])
        cert2 = load_pem_x509_certificate(cert2_pem.encode(), default_backend())
        
        cert1.verify_directly_issued_by(cert2)
        cert0.verify_directly_issued_by(cert1)
        cert2.verify_directly_issued_by(self.root_ca)
    
    def _base64_to_pem(self, base64_data: str) -> str:
        cert_bytes = base64.b64decode(base64_data)
        return f"-----BEGIN CERTIFICATE-----\n{base64_data}\n-----END CERTIFICATE-----"
    
    def _verify_signature(self, signing_input: str, signature_b64: str, cert_b64: str):
        cert_pem = self._base64_to_pem(cert_b64)
        cert = load_pem_x509_certificate(cert_pem.encode(), default_backend())
        public_key = cert.public_key()
        
        signature = base64.urlsafe_b64decode(signature_b64 + '=' * (4 - len(signature_b64) % 4))
        signing_input_bytes = signing_input.encode('utf-8')
        
        public_key.verify(
            signature,
            signing_input_bytes,
            ec.ECDSA(hashes.SHA256())
        )
    
    def _verify_payload(self, payload: dict, expected_nonce: str, expected_bundle_name: str, expected_app_id: str):
        if payload['nonce'] != expected_nonce:
            raise ValueError(f"Nonce mismatch: expected {expected_nonce}, got {payload['nonce']}")
        
        if payload.get('hapBundleName') != expected_bundle_name:
            raise ValueError(f"Bundle name mismatch: expected {expected_bundle_name}, got {payload.get('hapBundleName')}")
        
        if payload.get('appId') != expected_app_id:
            raise ValueError(f"App ID mismatch: expected {expected_app_id}, got {payload.get('appId')}")

def verify_sys_integrity_enhanced(jws: str, nonce: str, bundle_name: str, app_id: str) -> dict:
    verifier = JWSVerifier()
    try:
        result = verifier.verify_jws(jws, nonce, bundle_name, app_id)
        return {
            'success': True,
            'verified': result['verified'],
            'basic_integrity': result['basic_integrity'],
            'risk_details': result['detail']
        }
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }

if __name__ == "__main__":
    jws_token = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXUyIsIng1YyI6WyIiLCIiLCIiXX0.eyJ..."
    nonce_value = "imEe1PCRcjGkBCAhOCh6ImADztOZ8ygxlWRs"
    bundle_name = "com.example.app"
    app_id = "123456789"
    
    result = verify_sys_integrity_enhanced(jws_token, nonce_value, bundle_name, app_id)
    print(json.dumps(result, indent=2))