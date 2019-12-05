#import "OCPCWrapper.h"
#import "PassportCrypto.h"
#import "PKCS7Parser.h"
#include <string.h>

@implementation OCPCWrapper

+ (NSData*) encryptWith3DESX:(NSData*) message key1:(NSData*) key1 key2: (NSData*) key2 {
    PassportCrypto::encryptWith3DES((unsigned char*)[message bytes], (char*)[key1 bytes], (char*)[key2 bytes], (unsigned char*)[message bytes], (int)[message length]);
    
    return message;
}

+ (NSData*) decryptWith3DES:(NSData*) encryptedMessage key1:(NSData*) key1 ke2:(NSData*) key2 {
    PassportCrypto::decryptWith3DES((unsigned char*)[encryptedMessage bytes], (char*)[key1 bytes], (char*)[key2 bytes], (unsigned char*)[encryptedMessage bytes], (int)[encryptedMessage length]);
    
    return encryptedMessage;
}

+ (NSData*) calculateXor:(NSData*)result c1:(NSData*) c1 c2:(NSData*) c2 {
    PassportCrypto::calculateXor((unsigned char *)[result bytes], (unsigned char *)[c1 bytes], (unsigned char *)[c2 bytes], (int)[c1 length]);
    
    return result;
}

+ (NSData*) calculate3DESMAC: (NSData*)mac message: (NSData*)message key1:(NSData*) key1 key2:(NSData*) key2 {
    
    PassportCrypto::calculate3DESMAC((unsigned char *)[mac bytes], (char *)[key1 bytes], (char *)[key2 bytes], (unsigned char *)[message bytes], (int) [message length]);
    
    return mac;
}

+ (NSData*) paddMessage:(NSData*) message {
    
    NSMutableData* paddedMessage = [[NSMutableData alloc] initWithCapacity:[message length] + 16];
    int paddedLength;
    
    PassportCrypto::paddMessage((unsigned char *)[message bytes], (int) [message length], (unsigned char *)[paddedMessage bytes], &paddedLength);
    [paddedMessage setLength:paddedLength];
    return paddedMessage;
}

+ (unsigned int) asn1ToInt:(NSData*) asn1 {
    unsigned int intVal;
    PassportCrypto::asn1ToInt((unsigned char *)[asn1 bytes], &intVal);
    
    return intVal;
}

+ (NSData*) intToAsn1:(unsigned int) intVal asn1:(NSData*)asn1 {
    unsigned int asn1Length;
    PassportCrypto::intToAsn1(intVal, (unsigned char *)[asn1 bytes], &asn1Length);
    
    return asn1;
}

+ (NSData*) intTo16bitsChar:(unsigned int) intVal intChar:(NSData*)intChar {
    
    PassportCrypto::intTo16bitsChar(intVal, (unsigned char *)[intChar bytes]);
    
    return intChar;
}

+ (unsigned int) from16bitsCharToInt:(NSData*) intChar {
    return PassportCrypto::from16bitsCharToInt((unsigned char *)[intChar bytes]);
}

+ (NSData*) unpad:(NSData*) padded {
    unsigned int unPaddedLength;
    
    PassportCrypto::unpad((unsigned char *)[padded bytes], (unsigned int) [padded length], &unPaddedLength);
    NSMutableData* unpadded = [[NSMutableData alloc] initWithData:padded];
    [unpadded setLength:unPaddedLength];
    return unpadded;
}

+ (NSData*) incrementSequenceCounter:(NSData*) sequenceCounter {
    PassportCrypto::incrementSequenceCounter((char *)[sequenceCounter bytes]);
    return sequenceCounter;
}


+ (NSData*) getMdAlg:(NSData*) sod {
    PKCS7Parser* parser = new PKCS7Parser((char *)[sod bytes], (unsigned int)[sod length]);
    
    
    if(parser->getMdAlg() == nullptr) {
        return nullptr;
    }
    
    NSMutableData* mdAlg = [[NSMutableData alloc] initWithLength:strlen((const char *)parser->getMdAlg())];
    memcpy((char *)[mdAlg bytes], parser->getMdAlg(), strlen((const char *)parser->getMdAlg()));
    
    return mdAlg;
}

+ (NSData*) getSigAlg:(NSData*) sod {
    PKCS7Parser* parser = new PKCS7Parser((char *)[sod bytes], (unsigned int)[sod length]);
    
    
    if(parser->getSigAlg() == nullptr) {
        return nullptr;
    }
    
    NSMutableData* sigAlg = [[NSMutableData alloc] initWithLength:strlen((const char *)parser->getSigAlg())];
    memcpy((char *)[sigAlg bytes], parser->getSigAlg(), strlen((const char *)parser->getSigAlg()));
    
    return sigAlg;
}

+ (NSData*) getIssuer:(NSData*) sod {
    PKCS7Parser* parser = new PKCS7Parser((char *)[sod bytes], (unsigned int)[sod length]);
    
    
    if(parser->getIssuer() == nullptr) {
        return nullptr;
    }
    
    NSMutableData* issuer = [[NSMutableData alloc] initWithLength:strlen((const char *)parser->getIssuer())];
    memcpy((char *)[issuer bytes], parser->getIssuer(), strlen((const char *)parser->getIssuer()));
    
    return issuer;
}

@end

