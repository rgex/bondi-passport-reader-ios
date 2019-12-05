#import <Foundation/Foundation.h>

@interface OCPCWrapper: NSObject

+ (NSData*) encryptWith3DESX:(NSData*) message key1:(NSData*) key1 key2: (NSData*) key2;
+ (NSData*) decryptWith3DES:(NSData*) encryptedMessage key1:(NSData*) key1 ke2:(NSData*) key2;
+ (NSData*) calculateXor:(NSData*)result c1:(NSData*) c1 c2:(NSData*) c2;
+ (NSData*) calculate3DESMAC: (NSData*)mac message: (NSData*)message key1:(NSData*) key1 key2:(NSData*) key2;
+ (NSData*) paddMessage:(NSData*) message;
+ (unsigned int) asn1ToInt:(NSData*) asn1;
+ (NSData*) intToAsn1:(unsigned int) intVal asn1:(NSData*)asn1;
+ (NSData*) intTo16bitsChar:(unsigned int) intVal intChar:(NSData*)intChar;
+ (unsigned int) from16bitsCharToInt:(NSData*) intChar;
+ (NSData*) unpad:(NSData*) padded;
+ (NSData*) incrementSequenceCounter:(NSData*) sequenceCounter;
+ (NSData*) get:(NSData*) sequenceCounter;
+ (NSData*) getMdAlg:(NSData*) sod;
+ (NSData*) getSigAlg:(NSData*) sod;
+ (NSData*) getIssuer:(NSData*) sod;

@end
