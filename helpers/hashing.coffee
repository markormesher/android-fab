crypto = require('crypto')
module.exports = {
	sha256: (data) -> crypto.createHash('sha256').update(data).digest('hex')
	md5: (data) -> crypto.createHash('md5').update(data).digest('hex')
}
