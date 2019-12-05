/**
 *
 * The PKCS7 element contained in the EF.SOD file of the passport contains element such as
 * - The Document Signing Certificate
 * - The hashes of all other Files contained on the passport.
 * - A Digital signature on those hashes using the Document Signing Certificate
 * The PKCS7Parser is responsible for recovering those elements.
 * See Doc9303 for more information
 *
 */

#ifndef PASSPORTREADER_PKCS7PARSER_H
#define PASSPORTREADER_PKCS7PARSER_H

#include <openssl/pkcs7.h>"
#include <vector>

using namespace std;

class PKCS7Parser {
private:
    PKCS7* p7 = NULL;
public:
    std::vector<unsigned char> getSignedPayload();
    std::vector<unsigned char> getLDSPayload();
    PKCS7Parser(char* sod, size_t sodSize);
    X509* getDscCertificate();
    bool hasError();
    unsigned char* getMdAlg();
    unsigned char* getSigAlg();
    unsigned char* getIssuer();
};

#endif //PASSPORTREADER_PKCS7PARSER_H
