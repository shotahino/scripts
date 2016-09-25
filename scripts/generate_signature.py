import sys
import base64
import hmac
import hashlib
s3Secret = sys.argv[1]
contentType = sys.argv[2]
dateValue = sys.argv[3]
resource = sys.argv[4]

stringToSign = "PUT\n\n"+contentType+"\n"+dateValue+"\n"+resource 
digest_maker = hmac.new(s3Secret.encode(), stringToSign.encode(), hashlib.sha1)
digest = digest_maker.digest()
#convert to base64
print(base64.b64encode(digest))
