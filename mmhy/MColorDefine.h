//
//  MColorDefine.h
//  mmhy
//
//  Created by Micker on 2018/7/17.
//  Copyright © 2018年 micker. All rights reserved.
//

#ifndef MColorDefine_h
#define MColorDefine_h

#define Mask8(x) ( (x) & 0xFF ) // Un masque est défini
#define R(x) ( Mask8(x) )       // Pour accèder au canal rouge il faut masquer les 8 premiers bits
#define G(x) ( Mask8(x >> 8 ) ) // Pour le vert, effectuer un décalage de 8 bits et masquer
#define B(x) ( Mask8(x >> 16) ) // Pour le bleu, effectuer un décalage de 16 bits et masquer
#define A(x) ( Mask8(x >> 24) ) // L'élément A est ajouté aux paramètres RGBA, avec un masquage des 24 premiers bits (pour obtenir au total 32 bits)
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )


#endif /* MColorDefine_h */
