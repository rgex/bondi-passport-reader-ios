#include <openssl/objects.h>
#include <openssl/evp.h>
#include <iostream>
#include <openssl/x509.h>
#include <openssl/asn1.h>
#include <openssl/err.h>
#include "PKCS7Parser.h"

std::vector<unsigned char> PKCS7Parser::getSignedPayload() {
    unsigned char *abuf = NULL;
    int alen;
    STACK_OF(X509_ATTRIBUTE) *sk;

    PKCS7_SIGNER_INFO *si;
    STACK_OF(PKCS7_SIGNER_INFO) *siStack;
    siStack = PKCS7_get_signer_info(p7);
    si = sk_PKCS7_SIGNER_INFO_value(siStack, 0);

    sk = si->auth_attr;
    alen = ASN1_item_i2d((ASN1_VALUE *)sk, &abuf,
                         ASN1_ITEM_rptr(PKCS7_ATTR_VERIFY));

    return std::vector<unsigned char>(abuf, abuf + alen);

}

std::vector<unsigned char> PKCS7Parser::getLDSPayload() {
    STACK_OF(X509) *certs = p7->d.sign->cert;
    char *buffer = NULL;
    BIO *bio_enc = BIO_new(BIO_s_mem());

    int result = PKCS7_verify(p7, certs, NULL, NULL, bio_enc, PKCS7_NOVERIFY);
    long length = BIO_get_mem_data(bio_enc, &buffer);

    char *ret = (char *) calloc (1, 1 + length);
    if (ret)
        memcpy(ret, buffer, length);

    BIO_set_close(bio_enc, BIO_CLOSE);
    BIO_free(bio_enc);

    ERR_print_errors_fp (stderr);

    return std::vector<unsigned char>(ret, ret + length);
}

PKCS7Parser::PKCS7Parser(char* sod, size_t sodSize) {
    BIO *bSod = BIO_new_mem_buf(sod, (int)sodSize);

    this->p7 = d2i_PKCS7_bio( bSod, &this->p7 );
}

X509* PKCS7Parser::getDscCertificate() {
    if(this->p7 == NULL) {
        return nullptr;
    }

    X509* dscCertificate;
    STACK_OF(X509) *dsCerts = this->p7->d.sign->cert;

    if (sk_X509_num(dsCerts) > 0) {
        dscCertificate = sk_X509_value(dsCerts, 0);
    }

    return dscCertificate;
}

bool PKCS7Parser::hasError() {
    if(this->p7 == NULL) {
        return true;
    }

    return false;
}

unsigned char* PKCS7Parser::getMdAlg() {
    if(p7 == nullptr) {
        return nullptr;
    }
    STACK_OF(X509_ALGOR) *md_algs = p7->d.sign->md_algs;
    X509_ALGOR *md_alg = sk_X509_ALGOR_value(md_algs,0);
    
    return (unsigned  char *)OBJ_nid2ln(OBJ_obj2nid(md_alg->algorithm));
}

unsigned char* PKCS7Parser::getSigAlg() {
    if(getDscCertificate() == nullptr) {
        return nullptr;
    }
    
    return (unsigned  char *)OBJ_nid2ln(X509_get_signature_nid(getDscCertificate()));
}

unsigned char* PKCS7Parser::getIssuer() {
    if(getDscCertificate() == nullptr) {
        return nullptr;
    }
    
    return (unsigned  char *)X509_NAME_oneline(X509_get_issuer_name(getDscCertificate()), 0, 0);
}
