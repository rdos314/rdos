
struct asn1_object_st {
    const char *sn, *ln;
    int nid;
    int length;
    const unsigned char *data;  /* data remains const after init */
    int flags;                  /* Should we free this one */
};

typedef struct asn1_object_st ASN1_OBJECT;

#define SN_undef                        "UNDEF"
#define LN_undef                        "undefined"
#define NID_undef                       0
#define OBJ_undef                       0L

#define SN_itu_t                "ITU-T"
#define LN_itu_t                "itu-t"
#define NID_itu_t               645
#define OBJ_itu_t               0L

#define NID_ccitt               404
#define OBJ_ccitt               OBJ_itu_t

#define SN_iso          "ISO"
#define LN_iso          "iso"
#define NID_iso         181
#define OBJ_iso         1L

#define SN_joint_iso_itu_t              "JOINT-ISO-ITU-T"
#define LN_joint_iso_itu_t              "joint-iso-itu-t"
#define NID_joint_iso_itu_t             646
#define OBJ_joint_iso_itu_t             2L

#define NID_joint_iso_ccitt             393
#define OBJ_joint_iso_ccitt             OBJ_joint_iso_itu_t

#define SN_member_body          "member-body"
#define LN_member_body          "ISO Member Body"
#define NID_member_body         182
#define OBJ_member_body         OBJ_iso,2L

#define SN_identified_organization              "identified-organization"
#define NID_identified_organization             676
#define OBJ_identified_organization             OBJ_iso,3L

#define SN_hmac_md5             "HMAC-MD5"
#define LN_hmac_md5             "hmac-md5"
#define NID_hmac_md5            780
#define OBJ_hmac_md5            OBJ_identified_organization,6L,1L,5L,5L,8L,1L,1L

#define SN_hmac_sha1            "HMAC-SHA1"
#define LN_hmac_sha1            "hmac-sha1"
#define NID_hmac_sha1           781
#define OBJ_hmac_sha1           OBJ_identified_organization,6L,1L,5L,5L,8L,1L,2L

#define SN_x509ExtAdmission             "x509ExtAdmission"
#define LN_x509ExtAdmission             "Professional Information or basis for Admission"
#define NID_x509ExtAdmission            1093
#define OBJ_x509ExtAdmission            OBJ_identified_organization,36L,8L,3L,3L

#define SN_certicom_arc         "certicom-arc"
#define NID_certicom_arc                677
#define OBJ_certicom_arc                OBJ_identified_organization,132L

#define SN_ieee         "ieee"
#define NID_ieee                1170
#define OBJ_ieee                OBJ_identified_organization,111L

#define SN_ieee_siswg           "ieee-siswg"
#define LN_ieee_siswg           "IEEE Security in Storage Working Group"
#define NID_ieee_siswg          1171
#define OBJ_ieee_siswg          OBJ_ieee,2L,1619L

#define SN_international_organizations          "international-organizations"
#define LN_international_organizations          "International Organizations"
#define NID_international_organizations         647
#define OBJ_international_organizations         OBJ_joint_iso_itu_t,23L

#define SN_wap          "wap"
#define NID_wap         678
#define OBJ_wap         OBJ_international_organizations,43L

#define SN_wap_wsg              "wap-wsg"
#define NID_wap_wsg             679
#define OBJ_wap_wsg             OBJ_wap,1L

#define SN_selected_attribute_types             "selected-attribute-types"
#define LN_selected_attribute_types             "Selected Attribute Types"
#define NID_selected_attribute_types            394
#define OBJ_selected_attribute_types            OBJ_joint_iso_itu_t,5L,1L,5L

#define SN_clearance            "clearance"
#define NID_clearance           395
#define OBJ_clearance           OBJ_selected_attribute_types,55L

#define SN_ISO_US               "ISO-US"
#define LN_ISO_US               "ISO US Member Body"
#define NID_ISO_US              183
#define OBJ_ISO_US              OBJ_member_body,840L

#define SN_X9_57                "X9-57"
#define LN_X9_57                "X9.57"
#define NID_X9_57               184
#define OBJ_X9_57               OBJ_ISO_US,10040L

#define SN_X9cm         "X9cm"
#define LN_X9cm         "X9.57 CM ?"
#define NID_X9cm                185
#define OBJ_X9cm                OBJ_X9_57,4L

#define SN_ISO_CN               "ISO-CN"
#define LN_ISO_CN               "ISO CN Member Body"
#define NID_ISO_CN              1140
#define OBJ_ISO_CN              OBJ_member_body,156L

#define SN_oscca                "oscca"
#define NID_oscca               1141
#define OBJ_oscca               OBJ_ISO_CN,10197L

#define SN_sm_scheme            "sm-scheme"
#define NID_sm_scheme           1142
#define OBJ_sm_scheme           OBJ_oscca,1L

#define SN_dsa          "DSA"
#define LN_dsa          "dsaEncryption"
#define NID_dsa         116
#define OBJ_dsa         OBJ_X9cm,1L

#define SN_dsaWithSHA1          "DSA-SHA1"
#define LN_dsaWithSHA1          "dsaWithSHA1"
#define NID_dsaWithSHA1         113
#define OBJ_dsaWithSHA1         OBJ_X9cm,3L

#define SN_ansi_X9_62           "ansi-X9-62"
#define LN_ansi_X9_62           "ANSI X9.62"
#define NID_ansi_X9_62          405
#define OBJ_ansi_X9_62          OBJ_ISO_US,10045L

#define OBJ_X9_62_id_fieldType          OBJ_ansi_X9_62,1L

#define SN_X9_62_prime_field            "prime-field"
#define NID_X9_62_prime_field           406
#define OBJ_X9_62_prime_field           OBJ_X9_62_id_fieldType,1L

#define SN_X9_62_characteristic_two_field               "characteristic-two-field"
#define NID_X9_62_characteristic_two_field              407
#define OBJ_X9_62_characteristic_two_field              OBJ_X9_62_id_fieldType,2L

#define SN_X9_62_id_characteristic_two_basis            "id-characteristic-two-basis"
#define NID_X9_62_id_characteristic_two_basis           680
#define OBJ_X9_62_id_characteristic_two_basis           OBJ_X9_62_characteristic_two_field,3L

#define SN_X9_62_onBasis                "onBasis"
#define NID_X9_62_onBasis               681
#define OBJ_X9_62_onBasis               OBJ_X9_62_id_characteristic_two_basis,1L

#define SN_X9_62_tpBasis                "tpBasis"
#define NID_X9_62_tpBasis               682
#define OBJ_X9_62_tpBasis               OBJ_X9_62_id_characteristic_two_basis,2L

#define SN_X9_62_ppBasis                "ppBasis"
#define NID_X9_62_ppBasis               683
#define OBJ_X9_62_ppBasis               OBJ_X9_62_id_characteristic_two_basis,3L

#define OBJ_X9_62_id_publicKeyType              OBJ_ansi_X9_62,2L

#define SN_X9_62_id_ecPublicKey         "id-ecPublicKey"
#define NID_X9_62_id_ecPublicKey                408
#define OBJ_X9_62_id_ecPublicKey                OBJ_X9_62_id_publicKeyType,1L

#define OBJ_X9_62_ellipticCurve         OBJ_ansi_X9_62,3L

#define OBJ_X9_62_c_TwoCurve            OBJ_X9_62_ellipticCurve,0L

#define SN_X9_62_c2pnb163v1             "c2pnb163v1"
#define NID_X9_62_c2pnb163v1            684
#define OBJ_X9_62_c2pnb163v1            OBJ_X9_62_c_TwoCurve,1L

#define SN_X9_62_c2pnb163v2             "c2pnb163v2"
#define NID_X9_62_c2pnb163v2            685
#define OBJ_X9_62_c2pnb163v2            OBJ_X9_62_c_TwoCurve,2L

#define SN_X9_62_c2pnb163v3             "c2pnb163v3"
#define NID_X9_62_c2pnb163v3            686
#define OBJ_X9_62_c2pnb163v3            OBJ_X9_62_c_TwoCurve,3L

#define SN_X9_62_c2pnb176v1             "c2pnb176v1"
#define NID_X9_62_c2pnb176v1            687
#define OBJ_X9_62_c2pnb176v1            OBJ_X9_62_c_TwoCurve,4L

#define SN_X9_62_c2tnb191v1             "c2tnb191v1"
#define NID_X9_62_c2tnb191v1            688
#define OBJ_X9_62_c2tnb191v1            OBJ_X9_62_c_TwoCurve,5L

#define SN_X9_62_c2tnb191v2             "c2tnb191v2"
#define NID_X9_62_c2tnb191v2            689
#define OBJ_X9_62_c2tnb191v2            OBJ_X9_62_c_TwoCurve,6L

#define SN_X9_62_c2tnb191v3             "c2tnb191v3"
#define NID_X9_62_c2tnb191v3            690
#define OBJ_X9_62_c2tnb191v3            OBJ_X9_62_c_TwoCurve,7L

#define SN_X9_62_c2onb191v4             "c2onb191v4"
#define NID_X9_62_c2onb191v4            691
#define OBJ_X9_62_c2onb191v4            OBJ_X9_62_c_TwoCurve,8L

#define SN_X9_62_c2onb191v5             "c2onb191v5"
#define NID_X9_62_c2onb191v5            692
#define OBJ_X9_62_c2onb191v5            OBJ_X9_62_c_TwoCurve,9L

#define SN_X9_62_c2pnb208w1             "c2pnb208w1"
#define NID_X9_62_c2pnb208w1            693
#define OBJ_X9_62_c2pnb208w1            OBJ_X9_62_c_TwoCurve,10L

#define SN_X9_62_c2tnb239v1             "c2tnb239v1"
#define NID_X9_62_c2tnb239v1            694
#define OBJ_X9_62_c2tnb239v1            OBJ_X9_62_c_TwoCurve,11L

#define SN_X9_62_c2tnb239v2             "c2tnb239v2"
#define NID_X9_62_c2tnb239v2            695
#define OBJ_X9_62_c2tnb239v2            OBJ_X9_62_c_TwoCurve,12L

#define SN_X9_62_c2tnb239v3             "c2tnb239v3"
#define NID_X9_62_c2tnb239v3            696
#define OBJ_X9_62_c2tnb239v3            OBJ_X9_62_c_TwoCurve,13L

#define SN_X9_62_c2onb239v4             "c2onb239v4"
#define NID_X9_62_c2onb239v4            697
#define OBJ_X9_62_c2onb239v4            OBJ_X9_62_c_TwoCurve,14L

#define SN_X9_62_c2onb239v5             "c2onb239v5"
#define NID_X9_62_c2onb239v5            698
#define OBJ_X9_62_c2onb239v5            OBJ_X9_62_c_TwoCurve,15L

#define SN_X9_62_c2pnb272w1             "c2pnb272w1"
#define NID_X9_62_c2pnb272w1            699
#define OBJ_X9_62_c2pnb272w1            OBJ_X9_62_c_TwoCurve,16L

#define SN_X9_62_c2pnb304w1             "c2pnb304w1"
#define NID_X9_62_c2pnb304w1            700
#define OBJ_X9_62_c2pnb304w1            OBJ_X9_62_c_TwoCurve,17L

#define SN_X9_62_c2tnb359v1             "c2tnb359v1"
#define NID_X9_62_c2tnb359v1            701
#define OBJ_X9_62_c2tnb359v1            OBJ_X9_62_c_TwoCurve,18L

#define SN_X9_62_c2pnb368w1             "c2pnb368w1"
#define NID_X9_62_c2pnb368w1            702
#define OBJ_X9_62_c2pnb368w1            OBJ_X9_62_c_TwoCurve,19L

#define SN_X9_62_c2tnb431r1             "c2tnb431r1"
#define NID_X9_62_c2tnb431r1            703
#define OBJ_X9_62_c2tnb431r1            OBJ_X9_62_c_TwoCurve,20L

#define OBJ_X9_62_primeCurve            OBJ_X9_62_ellipticCurve,1L

#define SN_X9_62_prime192v1             "prime192v1"
#define NID_X9_62_prime192v1            409
#define OBJ_X9_62_prime192v1            OBJ_X9_62_primeCurve,1L

#define SN_X9_62_prime192v2             "prime192v2"
#define NID_X9_62_prime192v2            410
#define OBJ_X9_62_prime192v2            OBJ_X9_62_primeCurve,2L

#define SN_X9_62_prime192v3             "prime192v3"
#define NID_X9_62_prime192v3            411
#define OBJ_X9_62_prime192v3            OBJ_X9_62_primeCurve,3L

#define SN_X9_62_prime239v1             "prime239v1"
#define NID_X9_62_prime239v1            412
#define OBJ_X9_62_prime239v1            OBJ_X9_62_primeCurve,4L

#define SN_X9_62_prime239v2             "prime239v2"
#define NID_X9_62_prime239v2            413
#define OBJ_X9_62_prime239v2            OBJ_X9_62_primeCurve,5L

#define SN_X9_62_prime239v3             "prime239v3"
#define NID_X9_62_prime239v3            414
#define OBJ_X9_62_prime239v3            OBJ_X9_62_primeCurve,6L

#define SN_X9_62_prime256v1             "prime256v1"
#define NID_X9_62_prime256v1            415
#define OBJ_X9_62_prime256v1            OBJ_X9_62_primeCurve,7L

#define OBJ_X9_62_id_ecSigType          OBJ_ansi_X9_62,4L

#define SN_ecdsa_with_SHA1              "ecdsa-with-SHA1"
#define NID_ecdsa_with_SHA1             416
#define OBJ_ecdsa_with_SHA1             OBJ_X9_62_id_ecSigType,1L

#define SN_ecdsa_with_Recommended               "ecdsa-with-Recommended"
#define NID_ecdsa_with_Recommended              791
#define OBJ_ecdsa_with_Recommended              OBJ_X9_62_id_ecSigType,2L

#define SN_ecdsa_with_Specified         "ecdsa-with-Specified"
#define NID_ecdsa_with_Specified                792
#define OBJ_ecdsa_with_Specified                OBJ_X9_62_id_ecSigType,3L

#define SN_ecdsa_with_SHA224            "ecdsa-with-SHA224"
#define NID_ecdsa_with_SHA224           793
#define OBJ_ecdsa_with_SHA224           OBJ_ecdsa_with_Specified,1L

#define SN_ecdsa_with_SHA256            "ecdsa-with-SHA256"
#define NID_ecdsa_with_SHA256           794
#define OBJ_ecdsa_with_SHA256           OBJ_ecdsa_with_Specified,2L

#define SN_ecdsa_with_SHA384            "ecdsa-with-SHA384"
#define NID_ecdsa_with_SHA384           795
#define OBJ_ecdsa_with_SHA384           OBJ_ecdsa_with_Specified,3L

#define SN_ecdsa_with_SHA512            "ecdsa-with-SHA512"
#define NID_ecdsa_with_SHA512           796
#define OBJ_ecdsa_with_SHA512           OBJ_ecdsa_with_Specified,4L

#define OBJ_secg_ellipticCurve          OBJ_certicom_arc,0L

#define SN_secp112r1            "secp112r1"
#define NID_secp112r1           704
#define OBJ_secp112r1           OBJ_secg_ellipticCurve,6L

#define SN_secp112r2            "secp112r2"
#define NID_secp112r2           705
#define OBJ_secp112r2           OBJ_secg_ellipticCurve,7L

#define SN_secp128r1            "secp128r1"
#define NID_secp128r1           706
#define OBJ_secp128r1           OBJ_secg_ellipticCurve,28L

#define SN_secp128r2            "secp128r2"
#define NID_secp128r2           707
#define OBJ_secp128r2           OBJ_secg_ellipticCurve,29L

#define SN_secp160k1            "secp160k1"
#define NID_secp160k1           708
#define OBJ_secp160k1           OBJ_secg_ellipticCurve,9L

#define SN_secp160r1            "secp160r1"
#define NID_secp160r1           709
#define OBJ_secp160r1           OBJ_secg_ellipticCurve,8L

#define SN_secp160r2            "secp160r2"
#define NID_secp160r2           710
#define OBJ_secp160r2           OBJ_secg_ellipticCurve,30L

#define SN_secp192k1            "secp192k1"
#define NID_secp192k1           711
#define OBJ_secp192k1           OBJ_secg_ellipticCurve,31L

#define SN_secp224k1            "secp224k1"
#define NID_secp224k1           712
#define OBJ_secp224k1           OBJ_secg_ellipticCurve,32L

#define SN_secp224r1            "secp224r1"
#define NID_secp224r1           713
#define OBJ_secp224r1           OBJ_secg_ellipticCurve,33L

#define SN_secp256k1            "secp256k1"
#define NID_secp256k1           714
#define OBJ_secp256k1           OBJ_secg_ellipticCurve,10L

#define SN_secp384r1            "secp384r1"
#define NID_secp384r1           715
#define OBJ_secp384r1           OBJ_secg_ellipticCurve,34L

#define SN_secp521r1            "secp521r1"
#define NID_secp521r1           716
#define OBJ_secp521r1           OBJ_secg_ellipticCurve,35L

#define SN_sect113r1            "sect113r1"
#define NID_sect113r1           717
#define OBJ_sect113r1           OBJ_secg_ellipticCurve,4L

#define SN_sect113r2            "sect113r2"
#define NID_sect113r2           718
#define OBJ_sect113r2           OBJ_secg_ellipticCurve,5L

#define SN_sect131r1            "sect131r1"
#define NID_sect131r1           719
#define OBJ_sect131r1           OBJ_secg_ellipticCurve,22L

#define SN_sect131r2            "sect131r2"
#define NID_sect131r2           720
#define OBJ_sect131r2           OBJ_secg_ellipticCurve,23L

#define SN_sect163k1            "sect163k1"
#define NID_sect163k1           721
#define OBJ_sect163k1           OBJ_secg_ellipticCurve,1L

#define SN_sect163r1            "sect163r1"
#define NID_sect163r1           722
#define OBJ_sect163r1           OBJ_secg_ellipticCurve,2L

#define SN_sect163r2            "sect163r2"
#define NID_sect163r2           723
#define OBJ_sect163r2           OBJ_secg_ellipticCurve,15L

#define SN_sect193r1            "sect193r1"
#define NID_sect193r1           724
#define OBJ_sect193r1           OBJ_secg_ellipticCurve,24L

#define SN_sect193r2            "sect193r2"
#define NID_sect193r2           725
#define OBJ_sect193r2           OBJ_secg_ellipticCurve,25L

#define SN_sect233k1            "sect233k1"
#define NID_sect233k1           726
#define OBJ_sect233k1           OBJ_secg_ellipticCurve,26L

#define SN_sect233r1            "sect233r1"
#define NID_sect233r1           727
#define OBJ_sect233r1           OBJ_secg_ellipticCurve,27L

#define SN_sect239k1            "sect239k1"
#define NID_sect239k1           728
#define OBJ_sect239k1           OBJ_secg_ellipticCurve,3L

#define SN_sect283k1            "sect283k1"
#define NID_sect283k1           729
#define OBJ_sect283k1           OBJ_secg_ellipticCurve,16L

#define SN_sect283r1            "sect283r1"
#define NID_sect283r1           730
#define OBJ_sect283r1           OBJ_secg_ellipticCurve,17L

#define SN_sect409k1            "sect409k1"
#define NID_sect409k1           731
#define OBJ_sect409k1           OBJ_secg_ellipticCurve,36L

#define SN_sect409r1            "sect409r1"
#define NID_sect409r1           732
#define OBJ_sect409r1           OBJ_secg_ellipticCurve,37L

#define SN_sect571k1            "sect571k1"
#define NID_sect571k1           733
#define OBJ_sect571k1           OBJ_secg_ellipticCurve,38L

#define SN_sect571r1            "sect571r1"
#define NID_sect571r1           734
#define OBJ_sect571r1           OBJ_secg_ellipticCurve,39L

#define OBJ_wap_wsg_idm_ecid            OBJ_wap_wsg,4L

#define SN_wap_wsg_idm_ecid_wtls1               "wap-wsg-idm-ecid-wtls1"
#define NID_wap_wsg_idm_ecid_wtls1              735
#define OBJ_wap_wsg_idm_ecid_wtls1              OBJ_wap_wsg_idm_ecid,1L

#define SN_wap_wsg_idm_ecid_wtls3               "wap-wsg-idm-ecid-wtls3"
#define NID_wap_wsg_idm_ecid_wtls3              736
#define OBJ_wap_wsg_idm_ecid_wtls3              OBJ_wap_wsg_idm_ecid,3L

#define SN_wap_wsg_idm_ecid_wtls4               "wap-wsg-idm-ecid-wtls4"
#define NID_wap_wsg_idm_ecid_wtls4              737
#define OBJ_wap_wsg_idm_ecid_wtls4              OBJ_wap_wsg_idm_ecid,4L

#define SN_wap_wsg_idm_ecid_wtls5               "wap-wsg-idm-ecid-wtls5"
#define NID_wap_wsg_idm_ecid_wtls5              738
#define OBJ_wap_wsg_idm_ecid_wtls5              OBJ_wap_wsg_idm_ecid,5L

#define SN_wap_wsg_idm_ecid_wtls6               "wap-wsg-idm-ecid-wtls6"
#define NID_wap_wsg_idm_ecid_wtls6              739
#define OBJ_wap_wsg_idm_ecid_wtls6              OBJ_wap_wsg_idm_ecid,6L

#define SN_wap_wsg_idm_ecid_wtls7               "wap-wsg-idm-ecid-wtls7"
#define NID_wap_wsg_idm_ecid_wtls7              740
#define OBJ_wap_wsg_idm_ecid_wtls7              OBJ_wap_wsg_idm_ecid,7L

#define SN_wap_wsg_idm_ecid_wtls8               "wap-wsg-idm-ecid-wtls8"
#define NID_wap_wsg_idm_ecid_wtls8              741
#define OBJ_wap_wsg_idm_ecid_wtls8              OBJ_wap_wsg_idm_ecid,8L

#define SN_wap_wsg_idm_ecid_wtls9               "wap-wsg-idm-ecid-wtls9"
#define NID_wap_wsg_idm_ecid_wtls9              742
#define OBJ_wap_wsg_idm_ecid_wtls9              OBJ_wap_wsg_idm_ecid,9L

#define SN_wap_wsg_idm_ecid_wtls10              "wap-wsg-idm-ecid-wtls10"
#define NID_wap_wsg_idm_ecid_wtls10             743
#define OBJ_wap_wsg_idm_ecid_wtls10             OBJ_wap_wsg_idm_ecid,10L

#define SN_wap_wsg_idm_ecid_wtls11              "wap-wsg-idm-ecid-wtls11"
#define NID_wap_wsg_idm_ecid_wtls11             744
#define OBJ_wap_wsg_idm_ecid_wtls11             OBJ_wap_wsg_idm_ecid,11L

#define SN_wap_wsg_idm_ecid_wtls12              "wap-wsg-idm-ecid-wtls12"
#define NID_wap_wsg_idm_ecid_wtls12             745
#define OBJ_wap_wsg_idm_ecid_wtls12             OBJ_wap_wsg_idm_ecid,12L

#define SN_cast5_cbc            "CAST5-CBC"
#define LN_cast5_cbc            "cast5-cbc"
#define NID_cast5_cbc           108
#define OBJ_cast5_cbc           OBJ_ISO_US,113533L,7L,66L,10L

#define SN_cast5_ecb            "CAST5-ECB"
#define LN_cast5_ecb            "cast5-ecb"
#define NID_cast5_ecb           109

#define SN_cast5_cfb64          "CAST5-CFB"
#define LN_cast5_cfb64          "cast5-cfb"
#define NID_cast5_cfb64         110

#define SN_cast5_ofb64          "CAST5-OFB"
#define LN_cast5_ofb64          "cast5-ofb"
#define NID_cast5_ofb64         111

#define LN_pbeWithMD5AndCast5_CBC               "pbeWithMD5AndCast5CBC"
#define NID_pbeWithMD5AndCast5_CBC              112
#define OBJ_pbeWithMD5AndCast5_CBC              OBJ_ISO_US,113533L,7L,66L,12L

#define SN_id_PasswordBasedMAC          "id-PasswordBasedMAC"
#define LN_id_PasswordBasedMAC          "password based MAC"
#define NID_id_PasswordBasedMAC         782
#define OBJ_id_PasswordBasedMAC         OBJ_ISO_US,113533L,7L,66L,13L

#define SN_id_DHBasedMac                "id-DHBasedMac"
#define LN_id_DHBasedMac                "Diffie-Hellman based MAC"
#define NID_id_DHBasedMac               783
#define OBJ_id_DHBasedMac               OBJ_ISO_US,113533L,7L,66L,30L

#define SN_rsadsi               "rsadsi"
#define LN_rsadsi               "RSA Data Security, Inc."
#define NID_rsadsi              1
#define OBJ_rsadsi              OBJ_ISO_US,113549L

#define SN_pkcs         "pkcs"
#define LN_pkcs         "RSA Data Security, Inc. PKCS"
#define NID_pkcs                2
#define OBJ_pkcs                OBJ_rsadsi,1L

#define SN_pkcs1                "pkcs1"
#define NID_pkcs1               186
#define OBJ_pkcs1               OBJ_pkcs,1L

#define LN_rsaEncryption                "rsaEncryption"
#define NID_rsaEncryption               6
#define OBJ_rsaEncryption               OBJ_pkcs1,1L

#define SN_md2WithRSAEncryption         "RSA-MD2"
#define LN_md2WithRSAEncryption         "md2WithRSAEncryption"
#define NID_md2WithRSAEncryption                7
#define OBJ_md2WithRSAEncryption                OBJ_pkcs1,2L

#define SN_md4WithRSAEncryption         "RSA-MD4"
#define LN_md4WithRSAEncryption         "md4WithRSAEncryption"
#define NID_md4WithRSAEncryption                396
#define OBJ_md4WithRSAEncryption                OBJ_pkcs1,3L

#define SN_md5WithRSAEncryption         "RSA-MD5"
#define LN_md5WithRSAEncryption         "md5WithRSAEncryption"
#define NID_md5WithRSAEncryption                8
#define OBJ_md5WithRSAEncryption                OBJ_pkcs1,4L

#define SN_sha1WithRSAEncryption                "RSA-SHA1"
#define LN_sha1WithRSAEncryption                "sha1WithRSAEncryption"
#define NID_sha1WithRSAEncryption               65
#define OBJ_sha1WithRSAEncryption               OBJ_pkcs1,5L

#define SN_rsaesOaep            "RSAES-OAEP"
#define LN_rsaesOaep            "rsaesOaep"
#define NID_rsaesOaep           919
#define OBJ_rsaesOaep           OBJ_pkcs1,7L

#define SN_mgf1         "MGF1"
#define LN_mgf1         "mgf1"
#define NID_mgf1                911
#define OBJ_mgf1                OBJ_pkcs1,8L

#define SN_pSpecified           "PSPECIFIED"
#define LN_pSpecified           "pSpecified"
#define NID_pSpecified          935
#define OBJ_pSpecified          OBJ_pkcs1,9L

#define SN_rsassaPss            "RSASSA-PSS"
#define LN_rsassaPss            "rsassaPss"
#define NID_rsassaPss           912
#define OBJ_rsassaPss           OBJ_pkcs1,10L

#define SN_sha256WithRSAEncryption              "RSA-SHA256"
#define LN_sha256WithRSAEncryption              "sha256WithRSAEncryption"
#define NID_sha256WithRSAEncryption             668
#define OBJ_sha256WithRSAEncryption             OBJ_pkcs1,11L

#define SN_sha384WithRSAEncryption              "RSA-SHA384"
#define LN_sha384WithRSAEncryption              "sha384WithRSAEncryption"
#define NID_sha384WithRSAEncryption             669
#define OBJ_sha384WithRSAEncryption             OBJ_pkcs1,12L

#define SN_sha512WithRSAEncryption              "RSA-SHA512"
#define LN_sha512WithRSAEncryption              "sha512WithRSAEncryption"
#define NID_sha512WithRSAEncryption             670
#define OBJ_sha512WithRSAEncryption             OBJ_pkcs1,13L

#define SN_sha224WithRSAEncryption              "RSA-SHA224"
#define LN_sha224WithRSAEncryption              "sha224WithRSAEncryption"
#define NID_sha224WithRSAEncryption             671
#define OBJ_sha224WithRSAEncryption             OBJ_pkcs1,14L

#define SN_sha512_224WithRSAEncryption          "RSA-SHA512/224"
#define LN_sha512_224WithRSAEncryption          "sha512-224WithRSAEncryption"
#define NID_sha512_224WithRSAEncryption         1145
#define OBJ_sha512_224WithRSAEncryption         OBJ_pkcs1,15L

#define SN_sha512_256WithRSAEncryption          "RSA-SHA512/256"
#define LN_sha512_256WithRSAEncryption          "sha512-256WithRSAEncryption"
#define NID_sha512_256WithRSAEncryption         1146
#define OBJ_sha512_256WithRSAEncryption         OBJ_pkcs1,16L

#define SN_pkcs3                "pkcs3"
#define NID_pkcs3               27
#define OBJ_pkcs3               OBJ_pkcs,3L

#define LN_dhKeyAgreement               "dhKeyAgreement"
#define NID_dhKeyAgreement              28
#define OBJ_dhKeyAgreement              OBJ_pkcs3,1L

#define SN_pkcs5                "pkcs5"
#define NID_pkcs5               187
#define OBJ_pkcs5               OBJ_pkcs,5L

#define SN_pbeWithMD2AndDES_CBC         "PBE-MD2-DES"
#define LN_pbeWithMD2AndDES_CBC         "pbeWithMD2AndDES-CBC"
#define NID_pbeWithMD2AndDES_CBC                9
#define OBJ_pbeWithMD2AndDES_CBC                OBJ_pkcs5,1L

#define SN_pbeWithMD5AndDES_CBC         "PBE-MD5-DES"
#define LN_pbeWithMD5AndDES_CBC         "pbeWithMD5AndDES-CBC"
#define NID_pbeWithMD5AndDES_CBC                10
#define OBJ_pbeWithMD5AndDES_CBC                OBJ_pkcs5,3L

#define SN_pbeWithMD2AndRC2_CBC         "PBE-MD2-RC2-64"
#define LN_pbeWithMD2AndRC2_CBC         "pbeWithMD2AndRC2-CBC"
#define NID_pbeWithMD2AndRC2_CBC                168
#define OBJ_pbeWithMD2AndRC2_CBC                OBJ_pkcs5,4L

#define SN_pbeWithMD5AndRC2_CBC         "PBE-MD5-RC2-64"
#define LN_pbeWithMD5AndRC2_CBC         "pbeWithMD5AndRC2-CBC"
#define NID_pbeWithMD5AndRC2_CBC                169
#define OBJ_pbeWithMD5AndRC2_CBC                OBJ_pkcs5,6L

#define SN_pbeWithSHA1AndDES_CBC                "PBE-SHA1-DES"
#define LN_pbeWithSHA1AndDES_CBC                "pbeWithSHA1AndDES-CBC"
#define NID_pbeWithSHA1AndDES_CBC               170
#define OBJ_pbeWithSHA1AndDES_CBC               OBJ_pkcs5,10L

#define SN_pbeWithSHA1AndRC2_CBC                "PBE-SHA1-RC2-64"
#define LN_pbeWithSHA1AndRC2_CBC                "pbeWithSHA1AndRC2-CBC"
#define NID_pbeWithSHA1AndRC2_CBC               68
#define OBJ_pbeWithSHA1AndRC2_CBC               OBJ_pkcs5,11L

#define LN_id_pbkdf2            "PBKDF2"
#define NID_id_pbkdf2           69
#define OBJ_id_pbkdf2           OBJ_pkcs5,12L

#define LN_pbes2                "PBES2"
#define NID_pbes2               161
#define OBJ_pbes2               OBJ_pkcs5,13L

#define LN_pbmac1               "PBMAC1"
#define NID_pbmac1              162
#define OBJ_pbmac1              OBJ_pkcs5,14L

#define SN_pkcs7                "pkcs7"
#define NID_pkcs7               20
#define OBJ_pkcs7               OBJ_pkcs,7L

#define LN_pkcs7_data           "pkcs7-data"
#define NID_pkcs7_data          21
#define OBJ_pkcs7_data          OBJ_pkcs7,1L

#define LN_pkcs7_signed         "pkcs7-signedData"
#define NID_pkcs7_signed                22
#define OBJ_pkcs7_signed                OBJ_pkcs7,2L

#define LN_pkcs7_enveloped              "pkcs7-envelopedData"
#define NID_pkcs7_enveloped             23
#define OBJ_pkcs7_enveloped             OBJ_pkcs7,3L

#define LN_pkcs7_signedAndEnveloped             "pkcs7-signedAndEnvelopedData"
#define NID_pkcs7_signedAndEnveloped            24
#define OBJ_pkcs7_signedAndEnveloped            OBJ_pkcs7,4L

#define LN_pkcs7_digest         "pkcs7-digestData"
#define NID_pkcs7_digest                25
#define OBJ_pkcs7_digest                OBJ_pkcs7,5L

#define LN_pkcs7_encrypted              "pkcs7-encryptedData"
#define NID_pkcs7_encrypted             26
#define OBJ_pkcs7_encrypted             OBJ_pkcs7,6L

#define SN_pkcs9                "pkcs9"
#define NID_pkcs9               47
#define OBJ_pkcs9               OBJ_pkcs,9L

#define LN_pkcs9_emailAddress           "emailAddress"
#define NID_pkcs9_emailAddress          48
#define OBJ_pkcs9_emailAddress          OBJ_pkcs9,1L

#define LN_pkcs9_unstructuredName               "unstructuredName"
#define NID_pkcs9_unstructuredName              49
#define OBJ_pkcs9_unstructuredName              OBJ_pkcs9,2L

#define LN_pkcs9_contentType            "contentType"
#define NID_pkcs9_contentType           50
#define OBJ_pkcs9_contentType           OBJ_pkcs9,3L

#define LN_pkcs9_messageDigest          "messageDigest"
#define NID_pkcs9_messageDigest         51
#define OBJ_pkcs9_messageDigest         OBJ_pkcs9,4L

#define LN_pkcs9_signingTime            "signingTime"
#define NID_pkcs9_signingTime           52
#define OBJ_pkcs9_signingTime           OBJ_pkcs9,5L

#define LN_pkcs9_countersignature               "countersignature"
#define NID_pkcs9_countersignature              53
#define OBJ_pkcs9_countersignature              OBJ_pkcs9,6L

#define LN_pkcs9_challengePassword              "challengePassword"
#define NID_pkcs9_challengePassword             54
#define OBJ_pkcs9_challengePassword             OBJ_pkcs9,7L

#define LN_pkcs9_unstructuredAddress            "unstructuredAddress"
#define NID_pkcs9_unstructuredAddress           55
#define OBJ_pkcs9_unstructuredAddress           OBJ_pkcs9,8L

#define LN_pkcs9_extCertAttributes              "extendedCertificateAttributes"
#define NID_pkcs9_extCertAttributes             56
#define OBJ_pkcs9_extCertAttributes             OBJ_pkcs9,9L

#define SN_ext_req              "extReq"
#define LN_ext_req              "Extension Request"
#define NID_ext_req             172
#define OBJ_ext_req             OBJ_pkcs9,14L

#define SN_SMIMECapabilities            "SMIME-CAPS"
#define LN_SMIMECapabilities            "S/MIME Capabilities"
#define NID_SMIMECapabilities           167
#define OBJ_SMIMECapabilities           OBJ_pkcs9,15L

#define SN_SMIME                "SMIME"
#define LN_SMIME                "S/MIME"
#define NID_SMIME               188
#define OBJ_SMIME               OBJ_pkcs9,16L

#define SN_id_smime_mod         "id-smime-mod"
#define NID_id_smime_mod                189
#define OBJ_id_smime_mod                OBJ_SMIME,0L

#define SN_id_smime_ct          "id-smime-ct"
#define NID_id_smime_ct         190
#define OBJ_id_smime_ct         OBJ_SMIME,1L

#define SN_id_smime_aa          "id-smime-aa"
#define NID_id_smime_aa         191
#define OBJ_id_smime_aa         OBJ_SMIME,2L

#define SN_id_smime_alg         "id-smime-alg"
#define NID_id_smime_alg                192
#define OBJ_id_smime_alg                OBJ_SMIME,3L

#define SN_id_smime_cd          "id-smime-cd"
#define NID_id_smime_cd         193
#define OBJ_id_smime_cd         OBJ_SMIME,4L

#define SN_id_smime_spq         "id-smime-spq"
#define NID_id_smime_spq                194
#define OBJ_id_smime_spq                OBJ_SMIME,5L

#define SN_id_smime_cti         "id-smime-cti"
#define NID_id_smime_cti                195
#define OBJ_id_smime_cti                OBJ_SMIME,6L

#define SN_id_smime_mod_cms             "id-smime-mod-cms"
#define NID_id_smime_mod_cms            196
#define OBJ_id_smime_mod_cms            OBJ_id_smime_mod,1L

#define SN_id_smime_mod_ess             "id-smime-mod-ess"
#define NID_id_smime_mod_ess            197
#define OBJ_id_smime_mod_ess            OBJ_id_smime_mod,2L

#define SN_id_smime_mod_oid             "id-smime-mod-oid"
#define NID_id_smime_mod_oid            198
#define OBJ_id_smime_mod_oid            OBJ_id_smime_mod,3L

#define SN_id_smime_mod_msg_v3          "id-smime-mod-msg-v3"
#define NID_id_smime_mod_msg_v3         199
#define OBJ_id_smime_mod_msg_v3         OBJ_id_smime_mod,4L

#define SN_id_smime_mod_ets_eSignature_88               "id-smime-mod-ets-eSignature-88"
#define NID_id_smime_mod_ets_eSignature_88              200
#define OBJ_id_smime_mod_ets_eSignature_88              OBJ_id_smime_mod,5L

#define SN_id_smime_mod_ets_eSignature_97               "id-smime-mod-ets-eSignature-97"
#define NID_id_smime_mod_ets_eSignature_97              201
#define OBJ_id_smime_mod_ets_eSignature_97              OBJ_id_smime_mod,6L

#define SN_id_smime_mod_ets_eSigPolicy_88               "id-smime-mod-ets-eSigPolicy-88"
#define NID_id_smime_mod_ets_eSigPolicy_88              202
#define OBJ_id_smime_mod_ets_eSigPolicy_88              OBJ_id_smime_mod,7L

#define SN_id_smime_mod_ets_eSigPolicy_97               "id-smime-mod-ets-eSigPolicy-97"
#define NID_id_smime_mod_ets_eSigPolicy_97              203
#define OBJ_id_smime_mod_ets_eSigPolicy_97              OBJ_id_smime_mod,8L

#define SN_id_smime_ct_receipt          "id-smime-ct-receipt"
#define NID_id_smime_ct_receipt         204
#define OBJ_id_smime_ct_receipt         OBJ_id_smime_ct,1L

#define SN_id_smime_ct_authData         "id-smime-ct-authData"
#define NID_id_smime_ct_authData                205
#define OBJ_id_smime_ct_authData                OBJ_id_smime_ct,2L

#define SN_id_smime_ct_publishCert              "id-smime-ct-publishCert"
#define NID_id_smime_ct_publishCert             206
#define OBJ_id_smime_ct_publishCert             OBJ_id_smime_ct,3L

#define SN_id_smime_ct_TSTInfo          "id-smime-ct-TSTInfo"
#define NID_id_smime_ct_TSTInfo         207
#define OBJ_id_smime_ct_TSTInfo         OBJ_id_smime_ct,4L

#define SN_id_smime_ct_TDTInfo          "id-smime-ct-TDTInfo"
#define NID_id_smime_ct_TDTInfo         208
#define OBJ_id_smime_ct_TDTInfo         OBJ_id_smime_ct,5L

#define SN_id_smime_ct_contentInfo              "id-smime-ct-contentInfo"
#define NID_id_smime_ct_contentInfo             209
#define OBJ_id_smime_ct_contentInfo             OBJ_id_smime_ct,6L

#define SN_id_smime_ct_DVCSRequestData          "id-smime-ct-DVCSRequestData"
#define NID_id_smime_ct_DVCSRequestData         210
#define OBJ_id_smime_ct_DVCSRequestData         OBJ_id_smime_ct,7L

#define SN_id_smime_ct_DVCSResponseData         "id-smime-ct-DVCSResponseData"
#define NID_id_smime_ct_DVCSResponseData                211
#define OBJ_id_smime_ct_DVCSResponseData                OBJ_id_smime_ct,8L

#define SN_id_smime_ct_compressedData           "id-smime-ct-compressedData"
#define NID_id_smime_ct_compressedData          786
#define OBJ_id_smime_ct_compressedData          OBJ_id_smime_ct,9L

#define SN_id_smime_ct_contentCollection                "id-smime-ct-contentCollection"
#define NID_id_smime_ct_contentCollection               1058
#define OBJ_id_smime_ct_contentCollection               OBJ_id_smime_ct,19L

#define SN_id_smime_ct_authEnvelopedData                "id-smime-ct-authEnvelopedData"
#define NID_id_smime_ct_authEnvelopedData               1059
#define OBJ_id_smime_ct_authEnvelopedData               OBJ_id_smime_ct,23L

#define SN_id_ct_asciiTextWithCRLF              "id-ct-asciiTextWithCRLF"
#define NID_id_ct_asciiTextWithCRLF             787
#define OBJ_id_ct_asciiTextWithCRLF             OBJ_id_smime_ct,27L

#define SN_id_ct_xml            "id-ct-xml"
#define NID_id_ct_xml           1060
#define OBJ_id_ct_xml           OBJ_id_smime_ct,28L

#define SN_id_smime_aa_receiptRequest           "id-smime-aa-receiptRequest"
#define NID_id_smime_aa_receiptRequest          212
#define OBJ_id_smime_aa_receiptRequest          OBJ_id_smime_aa,1L

#define SN_id_smime_aa_securityLabel            "id-smime-aa-securityLabel"
#define NID_id_smime_aa_securityLabel           213
#define OBJ_id_smime_aa_securityLabel           OBJ_id_smime_aa,2L

#define SN_id_smime_aa_mlExpandHistory          "id-smime-aa-mlExpandHistory"
#define NID_id_smime_aa_mlExpandHistory         214
#define OBJ_id_smime_aa_mlExpandHistory         OBJ_id_smime_aa,3L

#define SN_id_smime_aa_contentHint              "id-smime-aa-contentHint"
#define NID_id_smime_aa_contentHint             215
#define OBJ_id_smime_aa_contentHint             OBJ_id_smime_aa,4L

#define SN_id_smime_aa_msgSigDigest             "id-smime-aa-msgSigDigest"
#define NID_id_smime_aa_msgSigDigest            216
#define OBJ_id_smime_aa_msgSigDigest            OBJ_id_smime_aa,5L

#define SN_id_smime_aa_encapContentType         "id-smime-aa-encapContentType"
#define NID_id_smime_aa_encapContentType                217
#define OBJ_id_smime_aa_encapContentType                OBJ_id_smime_aa,6L

#define SN_id_smime_aa_contentIdentifier                "id-smime-aa-contentIdentifier"
#define NID_id_smime_aa_contentIdentifier               218
#define OBJ_id_smime_aa_contentIdentifier               OBJ_id_smime_aa,7L

#define SN_id_smime_aa_macValue         "id-smime-aa-macValue"
#define NID_id_smime_aa_macValue                219
#define OBJ_id_smime_aa_macValue                OBJ_id_smime_aa,8L

#define SN_id_smime_aa_equivalentLabels         "id-smime-aa-equivalentLabels"
#define NID_id_smime_aa_equivalentLabels                220
#define OBJ_id_smime_aa_equivalentLabels                OBJ_id_smime_aa,9L

#define SN_id_smime_aa_contentReference         "id-smime-aa-contentReference"
#define NID_id_smime_aa_contentReference                221
#define OBJ_id_smime_aa_contentReference                OBJ_id_smime_aa,10L

#define SN_id_smime_aa_encrypKeyPref            "id-smime-aa-encrypKeyPref"
#define NID_id_smime_aa_encrypKeyPref           222
#define OBJ_id_smime_aa_encrypKeyPref           OBJ_id_smime_aa,11L

#define SN_id_smime_aa_signingCertificate               "id-smime-aa-signingCertificate"
#define NID_id_smime_aa_signingCertificate              223
#define OBJ_id_smime_aa_signingCertificate              OBJ_id_smime_aa,12L

#define SN_id_smime_aa_smimeEncryptCerts                "id-smime-aa-smimeEncryptCerts"
#define NID_id_smime_aa_smimeEncryptCerts               224
#define OBJ_id_smime_aa_smimeEncryptCerts               OBJ_id_smime_aa,13L

#define SN_id_smime_aa_timeStampToken           "id-smime-aa-timeStampToken"
#define NID_id_smime_aa_timeStampToken          225
#define OBJ_id_smime_aa_timeStampToken          OBJ_id_smime_aa,14L

#define SN_id_smime_aa_ets_sigPolicyId          "id-smime-aa-ets-sigPolicyId"
#define NID_id_smime_aa_ets_sigPolicyId         226
#define OBJ_id_smime_aa_ets_sigPolicyId         OBJ_id_smime_aa,15L

#define SN_id_smime_aa_ets_commitmentType               "id-smime-aa-ets-commitmentType"
#define NID_id_smime_aa_ets_commitmentType              227
#define OBJ_id_smime_aa_ets_commitmentType              OBJ_id_smime_aa,16L

#define SN_id_smime_aa_ets_signerLocation               "id-smime-aa-ets-signerLocation"
#define NID_id_smime_aa_ets_signerLocation              228
#define OBJ_id_smime_aa_ets_signerLocation              OBJ_id_smime_aa,17L

#define SN_id_smime_aa_ets_signerAttr           "id-smime-aa-ets-signerAttr"
#define NID_id_smime_aa_ets_signerAttr          229
#define OBJ_id_smime_aa_ets_signerAttr          OBJ_id_smime_aa,18L

#define SN_id_smime_aa_ets_otherSigCert         "id-smime-aa-ets-otherSigCert"
#define NID_id_smime_aa_ets_otherSigCert                230
#define OBJ_id_smime_aa_ets_otherSigCert                OBJ_id_smime_aa,19L

#define SN_id_smime_aa_ets_contentTimestamp             "id-smime-aa-ets-contentTimestamp"
#define NID_id_smime_aa_ets_contentTimestamp            231
#define OBJ_id_smime_aa_ets_contentTimestamp            OBJ_id_smime_aa,20L

#define SN_id_smime_aa_ets_CertificateRefs              "id-smime-aa-ets-CertificateRefs"
#define NID_id_smime_aa_ets_CertificateRefs             232
#define OBJ_id_smime_aa_ets_CertificateRefs             OBJ_id_smime_aa,21L

#define SN_id_smime_aa_ets_RevocationRefs               "id-smime-aa-ets-RevocationRefs"
#define NID_id_smime_aa_ets_RevocationRefs              233
#define OBJ_id_smime_aa_ets_RevocationRefs              OBJ_id_smime_aa,22L

#define SN_id_smime_aa_ets_certValues           "id-smime-aa-ets-certValues"
#define NID_id_smime_aa_ets_certValues          234
#define OBJ_id_smime_aa_ets_certValues          OBJ_id_smime_aa,23L

#define SN_id_smime_aa_ets_revocationValues             "id-smime-aa-ets-revocationValues"
#define NID_id_smime_aa_ets_revocationValues            235
#define OBJ_id_smime_aa_ets_revocationValues            OBJ_id_smime_aa,24L

#define SN_id_smime_aa_ets_escTimeStamp         "id-smime-aa-ets-escTimeStamp"
#define NID_id_smime_aa_ets_escTimeStamp                236
#define OBJ_id_smime_aa_ets_escTimeStamp                OBJ_id_smime_aa,25L

#define SN_id_smime_aa_ets_certCRLTimestamp             "id-smime-aa-ets-certCRLTimestamp"
#define NID_id_smime_aa_ets_certCRLTimestamp            237
#define OBJ_id_smime_aa_ets_certCRLTimestamp            OBJ_id_smime_aa,26L

#define SN_id_smime_aa_ets_archiveTimeStamp             "id-smime-aa-ets-archiveTimeStamp"
#define NID_id_smime_aa_ets_archiveTimeStamp            238
#define OBJ_id_smime_aa_ets_archiveTimeStamp            OBJ_id_smime_aa,27L

#define SN_id_smime_aa_signatureType            "id-smime-aa-signatureType"
#define NID_id_smime_aa_signatureType           239
#define OBJ_id_smime_aa_signatureType           OBJ_id_smime_aa,28L

#define SN_id_smime_aa_dvcs_dvc         "id-smime-aa-dvcs-dvc"
#define NID_id_smime_aa_dvcs_dvc                240
#define OBJ_id_smime_aa_dvcs_dvc                OBJ_id_smime_aa,29L

#define SN_id_smime_aa_signingCertificateV2             "id-smime-aa-signingCertificateV2"
#define NID_id_smime_aa_signingCertificateV2            1086
#define OBJ_id_smime_aa_signingCertificateV2            OBJ_id_smime_aa,47L

#define SN_id_smime_alg_ESDHwith3DES            "id-smime-alg-ESDHwith3DES"
#define NID_id_smime_alg_ESDHwith3DES           241
#define OBJ_id_smime_alg_ESDHwith3DES           OBJ_id_smime_alg,1L

#define SN_id_smime_alg_ESDHwithRC2             "id-smime-alg-ESDHwithRC2"
#define NID_id_smime_alg_ESDHwithRC2            242
#define OBJ_id_smime_alg_ESDHwithRC2            OBJ_id_smime_alg,2L

#define SN_id_smime_alg_3DESwrap                "id-smime-alg-3DESwrap"
#define NID_id_smime_alg_3DESwrap               243
#define OBJ_id_smime_alg_3DESwrap               OBJ_id_smime_alg,3L

#define SN_id_smime_alg_RC2wrap         "id-smime-alg-RC2wrap"
#define NID_id_smime_alg_RC2wrap                244
#define OBJ_id_smime_alg_RC2wrap                OBJ_id_smime_alg,4L

#define SN_id_smime_alg_ESDH            "id-smime-alg-ESDH"
#define NID_id_smime_alg_ESDH           245
#define OBJ_id_smime_alg_ESDH           OBJ_id_smime_alg,5L

#define SN_id_smime_alg_CMS3DESwrap             "id-smime-alg-CMS3DESwrap"
#define NID_id_smime_alg_CMS3DESwrap            246
#define OBJ_id_smime_alg_CMS3DESwrap            OBJ_id_smime_alg,6L

#define SN_id_smime_alg_CMSRC2wrap              "id-smime-alg-CMSRC2wrap"
#define NID_id_smime_alg_CMSRC2wrap             247
#define OBJ_id_smime_alg_CMSRC2wrap             OBJ_id_smime_alg,7L

#define SN_id_alg_PWRI_KEK              "id-alg-PWRI-KEK"
#define NID_id_alg_PWRI_KEK             893
#define OBJ_id_alg_PWRI_KEK             OBJ_id_smime_alg,9L

#define SN_id_smime_cd_ldap             "id-smime-cd-ldap"
#define NID_id_smime_cd_ldap            248
#define OBJ_id_smime_cd_ldap            OBJ_id_smime_cd,1L

#define SN_id_smime_spq_ets_sqt_uri             "id-smime-spq-ets-sqt-uri"
#define NID_id_smime_spq_ets_sqt_uri            249
#define OBJ_id_smime_spq_ets_sqt_uri            OBJ_id_smime_spq,1L

#define SN_id_smime_spq_ets_sqt_unotice         "id-smime-spq-ets-sqt-unotice"
#define NID_id_smime_spq_ets_sqt_unotice                250
#define OBJ_id_smime_spq_ets_sqt_unotice                OBJ_id_smime_spq,2L

#define SN_id_smime_cti_ets_proofOfOrigin               "id-smime-cti-ets-proofOfOrigin"
#define NID_id_smime_cti_ets_proofOfOrigin              251
#define OBJ_id_smime_cti_ets_proofOfOrigin              OBJ_id_smime_cti,1L

#define SN_id_smime_cti_ets_proofOfReceipt              "id-smime-cti-ets-proofOfReceipt"
#define NID_id_smime_cti_ets_proofOfReceipt             252
#define OBJ_id_smime_cti_ets_proofOfReceipt             OBJ_id_smime_cti,2L

#define SN_id_smime_cti_ets_proofOfDelivery             "id-smime-cti-ets-proofOfDelivery"
#define NID_id_smime_cti_ets_proofOfDelivery            253
#define OBJ_id_smime_cti_ets_proofOfDelivery            OBJ_id_smime_cti,3L

#define SN_id_smime_cti_ets_proofOfSender               "id-smime-cti-ets-proofOfSender"
#define NID_id_smime_cti_ets_proofOfSender              254
#define OBJ_id_smime_cti_ets_proofOfSender              OBJ_id_smime_cti,4L

#define SN_id_smime_cti_ets_proofOfApproval             "id-smime-cti-ets-proofOfApproval"
#define NID_id_smime_cti_ets_proofOfApproval            255
#define OBJ_id_smime_cti_ets_proofOfApproval            OBJ_id_smime_cti,5L

#define SN_id_smime_cti_ets_proofOfCreation             "id-smime-cti-ets-proofOfCreation"
#define NID_id_smime_cti_ets_proofOfCreation            256
#define OBJ_id_smime_cti_ets_proofOfCreation            OBJ_id_smime_cti,6L

#define LN_friendlyName         "friendlyName"
#define NID_friendlyName                156
#define OBJ_friendlyName                OBJ_pkcs9,20L

#define LN_localKeyID           "localKeyID"
#define NID_localKeyID          157
#define OBJ_localKeyID          OBJ_pkcs9,21L

#define SN_ms_csp_name          "CSPName"
#define LN_ms_csp_name          "Microsoft CSP Name"
#define NID_ms_csp_name         417
#define OBJ_ms_csp_name         1L,3L,6L,1L,4L,1L,311L,17L,1L

#define SN_LocalKeySet          "LocalKeySet"
#define LN_LocalKeySet          "Microsoft Local Key set"
#define NID_LocalKeySet         856
#define OBJ_LocalKeySet         1L,3L,6L,1L,4L,1L,311L,17L,2L

#define OBJ_certTypes           OBJ_pkcs9,22L

#define LN_x509Certificate              "x509Certificate"
#define NID_x509Certificate             158
#define OBJ_x509Certificate             OBJ_certTypes,1L

#define LN_sdsiCertificate              "sdsiCertificate"
#define NID_sdsiCertificate             159
#define OBJ_sdsiCertificate             OBJ_certTypes,2L

#define OBJ_crlTypes            OBJ_pkcs9,23L

#define LN_x509Crl              "x509Crl"
#define NID_x509Crl             160
#define OBJ_x509Crl             OBJ_crlTypes,1L

#define OBJ_pkcs12              OBJ_pkcs,12L

#define OBJ_pkcs12_pbeids               OBJ_pkcs12,1L

#define SN_pbe_WithSHA1And128BitRC4             "PBE-SHA1-RC4-128"
#define LN_pbe_WithSHA1And128BitRC4             "pbeWithSHA1And128BitRC4"
#define NID_pbe_WithSHA1And128BitRC4            144
#define OBJ_pbe_WithSHA1And128BitRC4            OBJ_pkcs12_pbeids,1L

#define SN_pbe_WithSHA1And40BitRC4              "PBE-SHA1-RC4-40"
#define LN_pbe_WithSHA1And40BitRC4              "pbeWithSHA1And40BitRC4"
#define NID_pbe_WithSHA1And40BitRC4             145
#define OBJ_pbe_WithSHA1And40BitRC4             OBJ_pkcs12_pbeids,2L

#define SN_pbe_WithSHA1And3_Key_TripleDES_CBC           "PBE-SHA1-3DES"
#define LN_pbe_WithSHA1And3_Key_TripleDES_CBC           "pbeWithSHA1And3-KeyTripleDES-CBC"
#define NID_pbe_WithSHA1And3_Key_TripleDES_CBC          146
#define OBJ_pbe_WithSHA1And3_Key_TripleDES_CBC          OBJ_pkcs12_pbeids,3L

#define SN_pbe_WithSHA1And2_Key_TripleDES_CBC           "PBE-SHA1-2DES"
#define LN_pbe_WithSHA1And2_Key_TripleDES_CBC           "pbeWithSHA1And2-KeyTripleDES-CBC"
#define NID_pbe_WithSHA1And2_Key_TripleDES_CBC          147
#define OBJ_pbe_WithSHA1And2_Key_TripleDES_CBC          OBJ_pkcs12_pbeids,4L

#define SN_pbe_WithSHA1And128BitRC2_CBC         "PBE-SHA1-RC2-128"
#define LN_pbe_WithSHA1And128BitRC2_CBC         "pbeWithSHA1And128BitRC2-CBC"
#define NID_pbe_WithSHA1And128BitRC2_CBC                148
#define OBJ_pbe_WithSHA1And128BitRC2_CBC                OBJ_pkcs12_pbeids,5L

#define SN_pbe_WithSHA1And40BitRC2_CBC          "PBE-SHA1-RC2-40"
#define LN_pbe_WithSHA1And40BitRC2_CBC          "pbeWithSHA1And40BitRC2-CBC"
#define NID_pbe_WithSHA1And40BitRC2_CBC         149
#define OBJ_pbe_WithSHA1And40BitRC2_CBC         OBJ_pkcs12_pbeids,6L

#define OBJ_pkcs12_Version1             OBJ_pkcs12,10L

#define OBJ_pkcs12_BagIds               OBJ_pkcs12_Version1,1L

#define LN_keyBag               "keyBag"
#define NID_keyBag              150
#define OBJ_keyBag              OBJ_pkcs12_BagIds,1L

#define LN_pkcs8ShroudedKeyBag          "pkcs8ShroudedKeyBag"
#define NID_pkcs8ShroudedKeyBag         151
#define OBJ_pkcs8ShroudedKeyBag         OBJ_pkcs12_BagIds,2L

#define LN_certBag              "certBag"
#define NID_certBag             152
#define OBJ_certBag             OBJ_pkcs12_BagIds,3L

#define LN_crlBag               "crlBag"
#define NID_crlBag              153
#define OBJ_crlBag              OBJ_pkcs12_BagIds,4L

#define LN_secretBag            "secretBag"
#define NID_secretBag           154
#define OBJ_secretBag           OBJ_pkcs12_BagIds,5L

#define LN_safeContentsBag              "safeContentsBag"
#define NID_safeContentsBag             155
#define OBJ_safeContentsBag             OBJ_pkcs12_BagIds,6L

#define SN_md2          "MD2"
#define LN_md2          "md2"
#define NID_md2         3
#define OBJ_md2         OBJ_rsadsi,2L,2L

#define SN_md4          "MD4"
#define LN_md4          "md4"
#define NID_md4         257
#define OBJ_md4         OBJ_rsadsi,2L,4L

#define SN_md5          "MD5"
#define LN_md5          "md5"
#define NID_md5         4
#define OBJ_md5         OBJ_rsadsi,2L,5L

#define SN_md5_sha1             "MD5-SHA1"
#define LN_md5_sha1             "md5-sha1"
#define NID_md5_sha1            114

#define LN_hmacWithMD5          "hmacWithMD5"
#define NID_hmacWithMD5         797
#define OBJ_hmacWithMD5         OBJ_rsadsi,2L,6L

#define LN_hmacWithSHA1         "hmacWithSHA1"
#define NID_hmacWithSHA1                163
#define OBJ_hmacWithSHA1                OBJ_rsadsi,2L,7L

#define SN_sm2          "SM2"
#define LN_sm2          "sm2"
#define NID_sm2         1172
#define OBJ_sm2         OBJ_sm_scheme,301L

#define SN_sm3          "SM3"
#define LN_sm3          "sm3"
#define NID_sm3         1143
#define OBJ_sm3         OBJ_sm_scheme,401L

#define SN_sm3WithRSAEncryption         "RSA-SM3"
#define LN_sm3WithRSAEncryption         "sm3WithRSAEncryption"
#define NID_sm3WithRSAEncryption                1144
#define OBJ_sm3WithRSAEncryption                OBJ_sm_scheme,504L

#define LN_hmacWithSHA224               "hmacWithSHA224"
#define NID_hmacWithSHA224              798
#define OBJ_hmacWithSHA224              OBJ_rsadsi,2L,8L

#define LN_hmacWithSHA256               "hmacWithSHA256"
#define NID_hmacWithSHA256              799
#define OBJ_hmacWithSHA256              OBJ_rsadsi,2L,9L

#define LN_hmacWithSHA384               "hmacWithSHA384"
#define NID_hmacWithSHA384              800
#define OBJ_hmacWithSHA384              OBJ_rsadsi,2L,10L

#define LN_hmacWithSHA512               "hmacWithSHA512"
#define NID_hmacWithSHA512              801
#define OBJ_hmacWithSHA512              OBJ_rsadsi,2L,11L

#define LN_hmacWithSHA512_224           "hmacWithSHA512-224"
#define NID_hmacWithSHA512_224          1193
#define OBJ_hmacWithSHA512_224          OBJ_rsadsi,2L,12L

#define LN_hmacWithSHA512_256           "hmacWithSHA512-256"
#define NID_hmacWithSHA512_256          1194
#define OBJ_hmacWithSHA512_256          OBJ_rsadsi,2L,13L

#define SN_rc2_cbc              "RC2-CBC"
#define LN_rc2_cbc              "rc2-cbc"
#define NID_rc2_cbc             37
#define OBJ_rc2_cbc             OBJ_rsadsi,3L,2L

#define SN_rc2_ecb              "RC2-ECB"
#define LN_rc2_ecb              "rc2-ecb"
#define NID_rc2_ecb             38

#define SN_rc2_cfb64            "RC2-CFB"
#define LN_rc2_cfb64            "rc2-cfb"
#define NID_rc2_cfb64           39

#define SN_rc2_ofb64            "RC2-OFB"
#define LN_rc2_ofb64            "rc2-ofb"
#define NID_rc2_ofb64           40

#define SN_rc2_40_cbc           "RC2-40-CBC"
#define LN_rc2_40_cbc           "rc2-40-cbc"
#define NID_rc2_40_cbc          98

#define SN_rc2_64_cbc           "RC2-64-CBC"
#define LN_rc2_64_cbc           "rc2-64-cbc"
#define NID_rc2_64_cbc          166

#define SN_rc4          "RC4"
#define LN_rc4          "rc4"
#define NID_rc4         5
#define OBJ_rc4         OBJ_rsadsi,3L,4L

#define SN_rc4_40               "RC4-40"
#define LN_rc4_40               "rc4-40"
#define NID_rc4_40              97

#define SN_des_ede3_cbc         "DES-EDE3-CBC"
#define LN_des_ede3_cbc         "des-ede3-cbc"
#define NID_des_ede3_cbc                44
#define OBJ_des_ede3_cbc                OBJ_rsadsi,3L,7L

#define SN_rc5_cbc              "RC5-CBC"
#define LN_rc5_cbc              "rc5-cbc"
#define NID_rc5_cbc             120
#define OBJ_rc5_cbc             OBJ_rsadsi,3L,8L

#define SN_rc5_ecb              "RC5-ECB"
#define LN_rc5_ecb              "rc5-ecb"
#define NID_rc5_ecb             121

#define SN_rc5_cfb64            "RC5-CFB"
#define LN_rc5_cfb64            "rc5-cfb"
#define NID_rc5_cfb64           122

#define SN_rc5_ofb64            "RC5-OFB"
#define LN_rc5_ofb64            "rc5-ofb"
#define NID_rc5_ofb64           123

#define SN_ms_ext_req           "msExtReq"
#define LN_ms_ext_req           "Microsoft Extension Request"
#define NID_ms_ext_req          171
#define OBJ_ms_ext_req          1L,3L,6L,1L,4L,1L,311L,2L,1L,14L

#define SN_ms_code_ind          "msCodeInd"
#define LN_ms_code_ind          "Microsoft Individual Code Signing"
#define NID_ms_code_ind         134
#define OBJ_ms_code_ind         1L,3L,6L,1L,4L,1L,311L,2L,1L,21L

#define SN_ms_code_com          "msCodeCom"
#define LN_ms_code_com          "Microsoft Commercial Code Signing"
#define NID_ms_code_com         135
#define OBJ_ms_code_com         1L,3L,6L,1L,4L,1L,311L,2L,1L,22L

#define SN_ms_ctl_sign          "msCTLSign"
#define LN_ms_ctl_sign          "Microsoft Trust List Signing"
#define NID_ms_ctl_sign         136
#define OBJ_ms_ctl_sign         1L,3L,6L,1L,4L,1L,311L,10L,3L,1L

#define SN_ms_sgc               "msSGC"
#define LN_ms_sgc               "Microsoft Server Gated Crypto"
#define NID_ms_sgc              137
#define OBJ_ms_sgc              1L,3L,6L,1L,4L,1L,311L,10L,3L,3L

#define SN_ms_efs               "msEFS"
#define LN_ms_efs               "Microsoft Encrypted File System"
#define NID_ms_efs              138
#define OBJ_ms_efs              1L,3L,6L,1L,4L,1L,311L,10L,3L,4L

#define SN_ms_smartcard_login           "msSmartcardLogin"
#define LN_ms_smartcard_login           "Microsoft Smartcard Login"
#define NID_ms_smartcard_login          648
#define OBJ_ms_smartcard_login          1L,3L,6L,1L,4L,1L,311L,20L,2L,2L

#define SN_ms_upn               "msUPN"
#define LN_ms_upn               "Microsoft User Principal Name"
#define NID_ms_upn              649
#define OBJ_ms_upn              1L,3L,6L,1L,4L,1L,311L,20L,2L,3L

#define SN_idea_cbc             "IDEA-CBC"
#define LN_idea_cbc             "idea-cbc"
#define NID_idea_cbc            34
#define OBJ_idea_cbc            1L,3L,6L,1L,4L,1L,188L,7L,1L,1L,2L

#define SN_idea_ecb             "IDEA-ECB"
#define LN_idea_ecb             "idea-ecb"
#define NID_idea_ecb            36

#define SN_idea_cfb64           "IDEA-CFB"
#define LN_idea_cfb64           "idea-cfb"
#define NID_idea_cfb64          35

#define SN_idea_ofb64           "IDEA-OFB"
#define LN_idea_ofb64           "idea-ofb"
#define NID_idea_ofb64          46

#define SN_bf_cbc               "BF-CBC"
#define LN_bf_cbc               "bf-cbc"
#define NID_bf_cbc              91
#define OBJ_bf_cbc              1L,3L,6L,1L,4L,1L,3029L,1L,2L

#define SN_bf_ecb               "BF-ECB"
#define LN_bf_ecb               "bf-ecb"
#define NID_bf_ecb              92

#define SN_bf_cfb64             "BF-CFB"
#define LN_bf_cfb64             "bf-cfb"
#define NID_bf_cfb64            93

#define SN_bf_ofb64             "BF-OFB"
#define LN_bf_ofb64             "bf-ofb"
#define NID_bf_ofb64            94

#define SN_id_pkix              "PKIX"
#define NID_id_pkix             127
#define OBJ_id_pkix             1L,3L,6L,1L,5L,5L,7L

#define SN_id_pkix_mod          "id-pkix-mod"
#define NID_id_pkix_mod         258
#define OBJ_id_pkix_mod         OBJ_id_pkix,0L

#define SN_id_pe                "id-pe"
#define NID_id_pe               175
#define OBJ_id_pe               OBJ_id_pkix,1L

#define SN_id_qt                "id-qt"
#define NID_id_qt               259
#define OBJ_id_qt               OBJ_id_pkix,2L

#define SN_id_kp                "id-kp"
#define NID_id_kp               128
#define OBJ_id_kp               OBJ_id_pkix,3L

#define SN_id_it                "id-it"
#define NID_id_it               260
#define OBJ_id_it               OBJ_id_pkix,4L

#define SN_id_pkip              "id-pkip"
#define NID_id_pkip             261
#define OBJ_id_pkip             OBJ_id_pkix,5L

#define SN_id_alg               "id-alg"
#define NID_id_alg              262
#define OBJ_id_alg              OBJ_id_pkix,6L

#define SN_id_cmc               "id-cmc"
#define NID_id_cmc              263
#define OBJ_id_cmc              OBJ_id_pkix,7L

#define SN_id_on                "id-on"
#define NID_id_on               264
#define OBJ_id_on               OBJ_id_pkix,8L

#define SN_id_pda               "id-pda"
#define NID_id_pda              265
#define OBJ_id_pda              OBJ_id_pkix,9L

#define SN_id_aca               "id-aca"
#define NID_id_aca              266
#define OBJ_id_aca              OBJ_id_pkix,10L

#define SN_id_qcs               "id-qcs"
#define NID_id_qcs              267
#define OBJ_id_qcs              OBJ_id_pkix,11L

#define SN_id_cct               "id-cct"
#define NID_id_cct              268
#define OBJ_id_cct              OBJ_id_pkix,12L

#define SN_id_ppl               "id-ppl"
#define NID_id_ppl              662
#define OBJ_id_ppl              OBJ_id_pkix,21L

#define SN_id_ad                "id-ad"
#define NID_id_ad               176
#define OBJ_id_ad               OBJ_id_pkix,48L

#define SN_id_pkix1_explicit_88         "id-pkix1-explicit-88"
#define NID_id_pkix1_explicit_88                269
#define OBJ_id_pkix1_explicit_88                OBJ_id_pkix_mod,1L

#define SN_id_pkix1_implicit_88         "id-pkix1-implicit-88"
#define NID_id_pkix1_implicit_88                270
#define OBJ_id_pkix1_implicit_88                OBJ_id_pkix_mod,2L

#define SN_id_pkix1_explicit_93         "id-pkix1-explicit-93"
#define NID_id_pkix1_explicit_93                271
#define OBJ_id_pkix1_explicit_93                OBJ_id_pkix_mod,3L

#define SN_id_pkix1_implicit_93         "id-pkix1-implicit-93"
#define NID_id_pkix1_implicit_93                272
#define OBJ_id_pkix1_implicit_93                OBJ_id_pkix_mod,4L

#define SN_id_mod_crmf          "id-mod-crmf"
#define NID_id_mod_crmf         273
#define OBJ_id_mod_crmf         OBJ_id_pkix_mod,5L

#define SN_id_mod_cmc           "id-mod-cmc"
#define NID_id_mod_cmc          274
#define OBJ_id_mod_cmc          OBJ_id_pkix_mod,6L

#define SN_id_mod_kea_profile_88                "id-mod-kea-profile-88"
#define NID_id_mod_kea_profile_88               275
#define OBJ_id_mod_kea_profile_88               OBJ_id_pkix_mod,7L

#define SN_id_mod_kea_profile_93                "id-mod-kea-profile-93"
#define NID_id_mod_kea_profile_93               276
#define OBJ_id_mod_kea_profile_93               OBJ_id_pkix_mod,8L

#define SN_id_mod_cmp           "id-mod-cmp"
#define NID_id_mod_cmp          277
#define OBJ_id_mod_cmp          OBJ_id_pkix_mod,9L

#define SN_id_mod_qualified_cert_88             "id-mod-qualified-cert-88"
#define NID_id_mod_qualified_cert_88            278
#define OBJ_id_mod_qualified_cert_88            OBJ_id_pkix_mod,10L

#define SN_id_mod_qualified_cert_93             "id-mod-qualified-cert-93"
#define NID_id_mod_qualified_cert_93            279
#define OBJ_id_mod_qualified_cert_93            OBJ_id_pkix_mod,11L

#define SN_id_mod_attribute_cert                "id-mod-attribute-cert"
#define NID_id_mod_attribute_cert               280
#define OBJ_id_mod_attribute_cert               OBJ_id_pkix_mod,12L

#define SN_id_mod_timestamp_protocol            "id-mod-timestamp-protocol"
#define NID_id_mod_timestamp_protocol           281
#define OBJ_id_mod_timestamp_protocol           OBJ_id_pkix_mod,13L

#define SN_id_mod_ocsp          "id-mod-ocsp"
#define NID_id_mod_ocsp         282
#define OBJ_id_mod_ocsp         OBJ_id_pkix_mod,14L

#define SN_id_mod_dvcs          "id-mod-dvcs"
#define NID_id_mod_dvcs         283
#define OBJ_id_mod_dvcs         OBJ_id_pkix_mod,15L

#define SN_id_mod_cmp2000               "id-mod-cmp2000"
#define NID_id_mod_cmp2000              284
#define OBJ_id_mod_cmp2000              OBJ_id_pkix_mod,16L

#define SN_info_access          "authorityInfoAccess"
#define LN_info_access          "Authority Information Access"
#define NID_info_access         177
#define OBJ_info_access         OBJ_id_pe,1L

#define SN_biometricInfo                "biometricInfo"
#define LN_biometricInfo                "Biometric Info"
#define NID_biometricInfo               285
#define OBJ_biometricInfo               OBJ_id_pe,2L

#define SN_qcStatements         "qcStatements"
#define NID_qcStatements                286
#define OBJ_qcStatements                OBJ_id_pe,3L

#define SN_ac_auditEntity               "ac-auditEntity"
#define NID_ac_auditEntity              287
#define OBJ_ac_auditEntity              OBJ_id_pe,4L

#define SN_ac_targeting         "ac-targeting"
#define NID_ac_targeting                288
#define OBJ_ac_targeting                OBJ_id_pe,5L

#define SN_aaControls           "aaControls"
#define NID_aaControls          289
#define OBJ_aaControls          OBJ_id_pe,6L

#define SN_sbgp_ipAddrBlock             "sbgp-ipAddrBlock"
#define NID_sbgp_ipAddrBlock            290
#define OBJ_sbgp_ipAddrBlock            OBJ_id_pe,7L

#define SN_sbgp_autonomousSysNum                "sbgp-autonomousSysNum"
#define NID_sbgp_autonomousSysNum               291
#define OBJ_sbgp_autonomousSysNum               OBJ_id_pe,8L

#define SN_sbgp_routerIdentifier                "sbgp-routerIdentifier"
#define NID_sbgp_routerIdentifier               292
#define OBJ_sbgp_routerIdentifier               OBJ_id_pe,9L

#define SN_ac_proxying          "ac-proxying"
#define NID_ac_proxying         397
#define OBJ_ac_proxying         OBJ_id_pe,10L

#define SN_sinfo_access         "subjectInfoAccess"
#define LN_sinfo_access         "Subject Information Access"
#define NID_sinfo_access                398
#define OBJ_sinfo_access                OBJ_id_pe,11L

#define SN_proxyCertInfo                "proxyCertInfo"
#define LN_proxyCertInfo                "Proxy Certificate Information"
#define NID_proxyCertInfo               663
#define OBJ_proxyCertInfo               OBJ_id_pe,14L

#define SN_tlsfeature           "tlsfeature"
#define LN_tlsfeature           "TLS Feature"
#define NID_tlsfeature          1020
#define OBJ_tlsfeature          OBJ_id_pe,24L

#define SN_id_qt_cps            "id-qt-cps"
#define LN_id_qt_cps            "Policy Qualifier CPS"
#define NID_id_qt_cps           164
#define OBJ_id_qt_cps           OBJ_id_qt,1L

#define SN_id_qt_unotice                "id-qt-unotice"
#define LN_id_qt_unotice                "Policy Qualifier User Notice"
#define NID_id_qt_unotice               165
#define OBJ_id_qt_unotice               OBJ_id_qt,2L

#define SN_textNotice           "textNotice"
#define NID_textNotice          293
#define OBJ_textNotice          OBJ_id_qt,3L

#define SN_server_auth          "serverAuth"
#define LN_server_auth          "TLS Web Server Authentication"
#define NID_server_auth         129
#define OBJ_server_auth         OBJ_id_kp,1L

#define SN_client_auth          "clientAuth"
#define LN_client_auth          "TLS Web Client Authentication"
#define NID_client_auth         130
#define OBJ_client_auth         OBJ_id_kp,2L

#define SN_code_sign            "codeSigning"
#define LN_code_sign            "Code Signing"
#define NID_code_sign           131
#define OBJ_code_sign           OBJ_id_kp,3L

#define SN_email_protect                "emailProtection"
#define LN_email_protect                "E-mail Protection"
#define NID_email_protect               132
#define OBJ_email_protect               OBJ_id_kp,4L

#define SN_ipsecEndSystem               "ipsecEndSystem"
#define LN_ipsecEndSystem               "IPSec End System"
#define NID_ipsecEndSystem              294
#define OBJ_ipsecEndSystem              OBJ_id_kp,5L

#define SN_ipsecTunnel          "ipsecTunnel"
#define LN_ipsecTunnel          "IPSec Tunnel"
#define NID_ipsecTunnel         295
#define OBJ_ipsecTunnel         OBJ_id_kp,6L

#define SN_ipsecUser            "ipsecUser"
#define LN_ipsecUser            "IPSec User"
#define NID_ipsecUser           296
#define OBJ_ipsecUser           OBJ_id_kp,7L

#define SN_time_stamp           "timeStamping"
#define LN_time_stamp           "Time Stamping"
#define NID_time_stamp          133
#define OBJ_time_stamp          OBJ_id_kp,8L

#define SN_OCSP_sign            "OCSPSigning"
#define LN_OCSP_sign            "OCSP Signing"
#define NID_OCSP_sign           180
#define OBJ_OCSP_sign           OBJ_id_kp,9L

#define SN_dvcs         "DVCS"
#define LN_dvcs         "dvcs"
#define NID_dvcs                297
#define OBJ_dvcs                OBJ_id_kp,10L

#define SN_ipsec_IKE            "ipsecIKE"
#define LN_ipsec_IKE            "ipsec Internet Key Exchange"
#define NID_ipsec_IKE           1022
#define OBJ_ipsec_IKE           OBJ_id_kp,17L

#define SN_capwapAC             "capwapAC"
#define LN_capwapAC             "Ctrl/provision WAP Access"
#define NID_capwapAC            1023
#define OBJ_capwapAC            OBJ_id_kp,18L

#define SN_capwapWTP            "capwapWTP"
#define LN_capwapWTP            "Ctrl/Provision WAP Termination"
#define NID_capwapWTP           1024
#define OBJ_capwapWTP           OBJ_id_kp,19L

#define SN_sshClient            "secureShellClient"
#define LN_sshClient            "SSH Client"
#define NID_sshClient           1025
#define OBJ_sshClient           OBJ_id_kp,21L

#define SN_sshServer            "secureShellServer"
#define LN_sshServer            "SSH Server"
#define NID_sshServer           1026
#define OBJ_sshServer           OBJ_id_kp,22L

#define SN_sendRouter           "sendRouter"
#define LN_sendRouter           "Send Router"
#define NID_sendRouter          1027
#define OBJ_sendRouter          OBJ_id_kp,23L

#define SN_sendProxiedRouter            "sendProxiedRouter"
#define LN_sendProxiedRouter            "Send Proxied Router"
#define NID_sendProxiedRouter           1028
#define OBJ_sendProxiedRouter           OBJ_id_kp,24L

#define SN_sendOwner            "sendOwner"
#define LN_sendOwner            "Send Owner"
#define NID_sendOwner           1029
#define OBJ_sendOwner           OBJ_id_kp,25L

#define SN_sendProxiedOwner             "sendProxiedOwner"
#define LN_sendProxiedOwner             "Send Proxied Owner"
#define NID_sendProxiedOwner            1030
#define OBJ_sendProxiedOwner            OBJ_id_kp,26L

#define SN_cmcCA                "cmcCA"
#define LN_cmcCA                "CMC Certificate Authority"
#define NID_cmcCA               1131
#define OBJ_cmcCA               OBJ_id_kp,27L

#define SN_cmcRA                "cmcRA"
#define LN_cmcRA                "CMC Registration Authority"
#define NID_cmcRA               1132
#define OBJ_cmcRA               OBJ_id_kp,28L

#define SN_id_it_caProtEncCert          "id-it-caProtEncCert"
#define NID_id_it_caProtEncCert         298
#define OBJ_id_it_caProtEncCert         OBJ_id_it,1L

#define SN_id_it_signKeyPairTypes               "id-it-signKeyPairTypes"
#define NID_id_it_signKeyPairTypes              299
#define OBJ_id_it_signKeyPairTypes              OBJ_id_it,2L

#define SN_id_it_encKeyPairTypes                "id-it-encKeyPairTypes"
#define NID_id_it_encKeyPairTypes               300
#define OBJ_id_it_encKeyPairTypes               OBJ_id_it,3L

#define SN_id_it_preferredSymmAlg               "id-it-preferredSymmAlg"
#define NID_id_it_preferredSymmAlg              301
#define OBJ_id_it_preferredSymmAlg              OBJ_id_it,4L

#define SN_id_it_caKeyUpdateInfo                "id-it-caKeyUpdateInfo"
#define NID_id_it_caKeyUpdateInfo               302
#define OBJ_id_it_caKeyUpdateInfo               OBJ_id_it,5L

#define SN_id_it_currentCRL             "id-it-currentCRL"
#define NID_id_it_currentCRL            303
#define OBJ_id_it_currentCRL            OBJ_id_it,6L

#define SN_id_it_unsupportedOIDs                "id-it-unsupportedOIDs"
#define NID_id_it_unsupportedOIDs               304
#define OBJ_id_it_unsupportedOIDs               OBJ_id_it,7L

#define SN_id_it_subscriptionRequest            "id-it-subscriptionRequest"
#define NID_id_it_subscriptionRequest           305
#define OBJ_id_it_subscriptionRequest           OBJ_id_it,8L

#define SN_id_it_subscriptionResponse           "id-it-subscriptionResponse"
#define NID_id_it_subscriptionResponse          306
#define OBJ_id_it_subscriptionResponse          OBJ_id_it,9L

#define SN_id_it_keyPairParamReq                "id-it-keyPairParamReq"
#define NID_id_it_keyPairParamReq               307
#define OBJ_id_it_keyPairParamReq               OBJ_id_it,10L

#define SN_id_it_keyPairParamRep                "id-it-keyPairParamRep"
#define NID_id_it_keyPairParamRep               308
#define OBJ_id_it_keyPairParamRep               OBJ_id_it,11L

#define SN_id_it_revPassphrase          "id-it-revPassphrase"
#define NID_id_it_revPassphrase         309
#define OBJ_id_it_revPassphrase         OBJ_id_it,12L

#define SN_id_it_implicitConfirm                "id-it-implicitConfirm"
#define NID_id_it_implicitConfirm               310
#define OBJ_id_it_implicitConfirm               OBJ_id_it,13L

#define SN_id_it_confirmWaitTime                "id-it-confirmWaitTime"
#define NID_id_it_confirmWaitTime               311
#define OBJ_id_it_confirmWaitTime               OBJ_id_it,14L

#define SN_id_it_origPKIMessage         "id-it-origPKIMessage"
#define NID_id_it_origPKIMessage                312
#define OBJ_id_it_origPKIMessage                OBJ_id_it,15L

#define SN_id_it_suppLangTags           "id-it-suppLangTags"
#define NID_id_it_suppLangTags          784
#define OBJ_id_it_suppLangTags          OBJ_id_it,16L

#define SN_id_regCtrl           "id-regCtrl"
#define NID_id_regCtrl          313
#define OBJ_id_regCtrl          OBJ_id_pkip,1L

#define SN_id_regInfo           "id-regInfo"
#define NID_id_regInfo          314
#define OBJ_id_regInfo          OBJ_id_pkip,2L

#define SN_id_regCtrl_regToken          "id-regCtrl-regToken"
#define NID_id_regCtrl_regToken         315
#define OBJ_id_regCtrl_regToken         OBJ_id_regCtrl,1L

#define SN_id_regCtrl_authenticator             "id-regCtrl-authenticator"
#define NID_id_regCtrl_authenticator            316
#define OBJ_id_regCtrl_authenticator            OBJ_id_regCtrl,2L

#define SN_id_regCtrl_pkiPublicationInfo                "id-regCtrl-pkiPublicationInfo"
#define NID_id_regCtrl_pkiPublicationInfo               317
#define OBJ_id_regCtrl_pkiPublicationInfo               OBJ_id_regCtrl,3L

#define SN_id_regCtrl_pkiArchiveOptions         "id-regCtrl-pkiArchiveOptions"
#define NID_id_regCtrl_pkiArchiveOptions                318
#define OBJ_id_regCtrl_pkiArchiveOptions                OBJ_id_regCtrl,4L

#define SN_id_regCtrl_oldCertID         "id-regCtrl-oldCertID"
#define NID_id_regCtrl_oldCertID                319
#define OBJ_id_regCtrl_oldCertID                OBJ_id_regCtrl,5L

#define SN_id_regCtrl_protocolEncrKey           "id-regCtrl-protocolEncrKey"
#define NID_id_regCtrl_protocolEncrKey          320
#define OBJ_id_regCtrl_protocolEncrKey          OBJ_id_regCtrl,6L

#define SN_id_regInfo_utf8Pairs         "id-regInfo-utf8Pairs"
#define NID_id_regInfo_utf8Pairs                321
#define OBJ_id_regInfo_utf8Pairs                OBJ_id_regInfo,1L

#define SN_id_regInfo_certReq           "id-regInfo-certReq"
#define NID_id_regInfo_certReq          322
#define OBJ_id_regInfo_certReq          OBJ_id_regInfo,2L

#define SN_id_alg_des40         "id-alg-des40"
#define NID_id_alg_des40                323
#define OBJ_id_alg_des40                OBJ_id_alg,1L

#define SN_id_alg_noSignature           "id-alg-noSignature"
#define NID_id_alg_noSignature          324
#define OBJ_id_alg_noSignature          OBJ_id_alg,2L

#define SN_id_alg_dh_sig_hmac_sha1              "id-alg-dh-sig-hmac-sha1"
#define NID_id_alg_dh_sig_hmac_sha1             325
#define OBJ_id_alg_dh_sig_hmac_sha1             OBJ_id_alg,3L

#define SN_id_alg_dh_pop                "id-alg-dh-pop"
#define NID_id_alg_dh_pop               326
#define OBJ_id_alg_dh_pop               OBJ_id_alg,4L

#define SN_id_cmc_statusInfo            "id-cmc-statusInfo"
#define NID_id_cmc_statusInfo           327
#define OBJ_id_cmc_statusInfo           OBJ_id_cmc,1L

#define SN_id_cmc_identification                "id-cmc-identification"
#define NID_id_cmc_identification               328
#define OBJ_id_cmc_identification               OBJ_id_cmc,2L

#define SN_id_cmc_identityProof         "id-cmc-identityProof"
#define NID_id_cmc_identityProof                329
#define OBJ_id_cmc_identityProof                OBJ_id_cmc,3L

#define SN_id_cmc_dataReturn            "id-cmc-dataReturn"
#define NID_id_cmc_dataReturn           330
#define OBJ_id_cmc_dataReturn           OBJ_id_cmc,4L

#define SN_id_cmc_transactionId         "id-cmc-transactionId"
#define NID_id_cmc_transactionId                331
#define OBJ_id_cmc_transactionId                OBJ_id_cmc,5L

#define SN_id_cmc_senderNonce           "id-cmc-senderNonce"
#define NID_id_cmc_senderNonce          332
#define OBJ_id_cmc_senderNonce          OBJ_id_cmc,6L

#define SN_id_cmc_recipientNonce                "id-cmc-recipientNonce"
#define NID_id_cmc_recipientNonce               333
#define OBJ_id_cmc_recipientNonce               OBJ_id_cmc,7L

#define SN_id_cmc_addExtensions         "id-cmc-addExtensions"
#define NID_id_cmc_addExtensions                334
#define OBJ_id_cmc_addExtensions                OBJ_id_cmc,8L

#define SN_id_cmc_encryptedPOP          "id-cmc-encryptedPOP"
#define NID_id_cmc_encryptedPOP         335
#define OBJ_id_cmc_encryptedPOP         OBJ_id_cmc,9L

#define SN_id_cmc_decryptedPOP          "id-cmc-decryptedPOP"
#define NID_id_cmc_decryptedPOP         336
#define OBJ_id_cmc_decryptedPOP         OBJ_id_cmc,10L

#define SN_id_cmc_lraPOPWitness         "id-cmc-lraPOPWitness"
#define NID_id_cmc_lraPOPWitness                337
#define OBJ_id_cmc_lraPOPWitness                OBJ_id_cmc,11L

#define SN_id_cmc_getCert               "id-cmc-getCert"
#define NID_id_cmc_getCert              338
#define OBJ_id_cmc_getCert              OBJ_id_cmc,15L

#define SN_id_cmc_getCRL                "id-cmc-getCRL"
#define NID_id_cmc_getCRL               339
#define OBJ_id_cmc_getCRL               OBJ_id_cmc,16L

#define SN_id_cmc_revokeRequest         "id-cmc-revokeRequest"
#define NID_id_cmc_revokeRequest                340
#define OBJ_id_cmc_revokeRequest                OBJ_id_cmc,17L

#define SN_id_cmc_regInfo               "id-cmc-regInfo"
#define NID_id_cmc_regInfo              341
#define OBJ_id_cmc_regInfo              OBJ_id_cmc,18L

#define SN_id_cmc_responseInfo          "id-cmc-responseInfo"
#define NID_id_cmc_responseInfo         342
#define OBJ_id_cmc_responseInfo         OBJ_id_cmc,19L

#define SN_id_cmc_queryPending          "id-cmc-queryPending"
#define NID_id_cmc_queryPending         343
#define OBJ_id_cmc_queryPending         OBJ_id_cmc,21L

#define SN_id_cmc_popLinkRandom         "id-cmc-popLinkRandom"
#define NID_id_cmc_popLinkRandom                344
#define OBJ_id_cmc_popLinkRandom                OBJ_id_cmc,22L

#define SN_id_cmc_popLinkWitness                "id-cmc-popLinkWitness"
#define NID_id_cmc_popLinkWitness               345
#define OBJ_id_cmc_popLinkWitness               OBJ_id_cmc,23L

#define SN_id_cmc_confirmCertAcceptance         "id-cmc-confirmCertAcceptance"
#define NID_id_cmc_confirmCertAcceptance                346
#define OBJ_id_cmc_confirmCertAcceptance                OBJ_id_cmc,24L

#define SN_id_on_personalData           "id-on-personalData"
#define NID_id_on_personalData          347
#define OBJ_id_on_personalData          OBJ_id_on,1L

#define SN_id_on_permanentIdentifier            "id-on-permanentIdentifier"
#define LN_id_on_permanentIdentifier            "Permanent Identifier"
#define NID_id_on_permanentIdentifier           858
#define OBJ_id_on_permanentIdentifier           OBJ_id_on,3L

#define SN_id_pda_dateOfBirth           "id-pda-dateOfBirth"
#define NID_id_pda_dateOfBirth          348
#define OBJ_id_pda_dateOfBirth          OBJ_id_pda,1L

#define SN_id_pda_placeOfBirth          "id-pda-placeOfBirth"
#define NID_id_pda_placeOfBirth         349
#define OBJ_id_pda_placeOfBirth         OBJ_id_pda,2L

#define SN_id_pda_gender                "id-pda-gender"
#define NID_id_pda_gender               351
#define OBJ_id_pda_gender               OBJ_id_pda,3L

#define SN_id_pda_countryOfCitizenship          "id-pda-countryOfCitizenship"
#define NID_id_pda_countryOfCitizenship         352
#define OBJ_id_pda_countryOfCitizenship         OBJ_id_pda,4L

#define SN_id_pda_countryOfResidence            "id-pda-countryOfResidence"
#define NID_id_pda_countryOfResidence           353
#define OBJ_id_pda_countryOfResidence           OBJ_id_pda,5L

#define SN_id_aca_authenticationInfo            "id-aca-authenticationInfo"
#define NID_id_aca_authenticationInfo           354
#define OBJ_id_aca_authenticationInfo           OBJ_id_aca,1L

#define SN_id_aca_accessIdentity                "id-aca-accessIdentity"
#define NID_id_aca_accessIdentity               355
#define OBJ_id_aca_accessIdentity               OBJ_id_aca,2L

#define SN_id_aca_chargingIdentity              "id-aca-chargingIdentity"
#define NID_id_aca_chargingIdentity             356
#define OBJ_id_aca_chargingIdentity             OBJ_id_aca,3L

#define SN_id_aca_group         "id-aca-group"
#define NID_id_aca_group                357
#define OBJ_id_aca_group                OBJ_id_aca,4L

#define SN_id_aca_role          "id-aca-role"
#define NID_id_aca_role         358
#define OBJ_id_aca_role         OBJ_id_aca,5L

#define SN_id_aca_encAttrs              "id-aca-encAttrs"
#define NID_id_aca_encAttrs             399
#define OBJ_id_aca_encAttrs             OBJ_id_aca,6L

#define SN_id_qcs_pkixQCSyntax_v1               "id-qcs-pkixQCSyntax-v1"
#define NID_id_qcs_pkixQCSyntax_v1              359
#define OBJ_id_qcs_pkixQCSyntax_v1              OBJ_id_qcs,1L

#define SN_id_cct_crs           "id-cct-crs"
#define NID_id_cct_crs          360
#define OBJ_id_cct_crs          OBJ_id_cct,1L

#define SN_id_cct_PKIData               "id-cct-PKIData"
#define NID_id_cct_PKIData              361
#define OBJ_id_cct_PKIData              OBJ_id_cct,2L

#define SN_id_cct_PKIResponse           "id-cct-PKIResponse"
#define NID_id_cct_PKIResponse          362
#define OBJ_id_cct_PKIResponse          OBJ_id_cct,3L

#define SN_id_ppl_anyLanguage           "id-ppl-anyLanguage"
#define LN_id_ppl_anyLanguage           "Any language"
#define NID_id_ppl_anyLanguage          664
#define OBJ_id_ppl_anyLanguage          OBJ_id_ppl,0L

#define SN_id_ppl_inheritAll            "id-ppl-inheritAll"
#define LN_id_ppl_inheritAll            "Inherit all"
#define NID_id_ppl_inheritAll           665
#define OBJ_id_ppl_inheritAll           OBJ_id_ppl,1L

#define SN_Independent          "id-ppl-independent"
#define LN_Independent          "Independent"
#define NID_Independent         667
#define OBJ_Independent         OBJ_id_ppl,2L

#define SN_ad_OCSP              "OCSP"
#define LN_ad_OCSP              "OCSP"
#define NID_ad_OCSP             178
#define OBJ_ad_OCSP             OBJ_id_ad,1L

#define SN_ad_ca_issuers                "caIssuers"
#define LN_ad_ca_issuers                "CA Issuers"
#define NID_ad_ca_issuers               179
#define OBJ_ad_ca_issuers               OBJ_id_ad,2L

#define SN_ad_timeStamping              "ad_timestamping"
#define LN_ad_timeStamping              "AD Time Stamping"
#define NID_ad_timeStamping             363
#define OBJ_ad_timeStamping             OBJ_id_ad,3L

#define SN_ad_dvcs              "AD_DVCS"
#define LN_ad_dvcs              "ad dvcs"
#define NID_ad_dvcs             364
#define OBJ_ad_dvcs             OBJ_id_ad,4L

#define SN_caRepository         "caRepository"
#define LN_caRepository         "CA Repository"
#define NID_caRepository                785
#define OBJ_caRepository                OBJ_id_ad,5L

#define OBJ_id_pkix_OCSP                OBJ_ad_OCSP

#define SN_id_pkix_OCSP_basic           "basicOCSPResponse"
#define LN_id_pkix_OCSP_basic           "Basic OCSP Response"
#define NID_id_pkix_OCSP_basic          365
#define OBJ_id_pkix_OCSP_basic          OBJ_id_pkix_OCSP,1L

#define SN_id_pkix_OCSP_Nonce           "Nonce"
#define LN_id_pkix_OCSP_Nonce           "OCSP Nonce"
#define NID_id_pkix_OCSP_Nonce          366
#define OBJ_id_pkix_OCSP_Nonce          OBJ_id_pkix_OCSP,2L

#define SN_id_pkix_OCSP_CrlID           "CrlID"
#define LN_id_pkix_OCSP_CrlID           "OCSP CRL ID"
#define NID_id_pkix_OCSP_CrlID          367
#define OBJ_id_pkix_OCSP_CrlID          OBJ_id_pkix_OCSP,3L

#define SN_id_pkix_OCSP_acceptableResponses             "acceptableResponses"
#define LN_id_pkix_OCSP_acceptableResponses             "Acceptable OCSP Responses"
#define NID_id_pkix_OCSP_acceptableResponses            368
#define OBJ_id_pkix_OCSP_acceptableResponses            OBJ_id_pkix_OCSP,4L

#define SN_id_pkix_OCSP_noCheck         "noCheck"
#define LN_id_pkix_OCSP_noCheck         "OCSP No Check"
#define NID_id_pkix_OCSP_noCheck                369
#define OBJ_id_pkix_OCSP_noCheck                OBJ_id_pkix_OCSP,5L

#define SN_id_pkix_OCSP_archiveCutoff           "archiveCutoff"
#define LN_id_pkix_OCSP_archiveCutoff           "OCSP Archive Cutoff"
#define NID_id_pkix_OCSP_archiveCutoff          370
#define OBJ_id_pkix_OCSP_archiveCutoff          OBJ_id_pkix_OCSP,6L

#define SN_id_pkix_OCSP_serviceLocator          "serviceLocator"
#define LN_id_pkix_OCSP_serviceLocator          "OCSP Service Locator"
#define NID_id_pkix_OCSP_serviceLocator         371
#define OBJ_id_pkix_OCSP_serviceLocator         OBJ_id_pkix_OCSP,7L

#define SN_id_pkix_OCSP_extendedStatus          "extendedStatus"
#define LN_id_pkix_OCSP_extendedStatus          "Extended OCSP Status"
#define NID_id_pkix_OCSP_extendedStatus         372
#define OBJ_id_pkix_OCSP_extendedStatus         OBJ_id_pkix_OCSP,8L

#define SN_id_pkix_OCSP_valid           "valid"
#define NID_id_pkix_OCSP_valid          373
#define OBJ_id_pkix_OCSP_valid          OBJ_id_pkix_OCSP,9L

#define SN_id_pkix_OCSP_path            "path"
#define NID_id_pkix_OCSP_path           374
#define OBJ_id_pkix_OCSP_path           OBJ_id_pkix_OCSP,10L

#define SN_id_pkix_OCSP_trustRoot               "trustRoot"
#define LN_id_pkix_OCSP_trustRoot               "Trust Root"
#define NID_id_pkix_OCSP_trustRoot              375
#define OBJ_id_pkix_OCSP_trustRoot              OBJ_id_pkix_OCSP,11L

#define SN_algorithm            "algorithm"
#define LN_algorithm            "algorithm"
#define NID_algorithm           376
#define OBJ_algorithm           1L,3L,14L,3L,2L

#define SN_md5WithRSA           "RSA-NP-MD5"
#define LN_md5WithRSA           "md5WithRSA"
#define NID_md5WithRSA          104
#define OBJ_md5WithRSA          OBJ_algorithm,3L

#define SN_des_ecb              "DES-ECB"
#define LN_des_ecb              "des-ecb"
#define NID_des_ecb             29
#define OBJ_des_ecb             OBJ_algorithm,6L

#define SN_des_cbc              "DES-CBC"
#define LN_des_cbc              "des-cbc"
#define NID_des_cbc             31
#define OBJ_des_cbc             OBJ_algorithm,7L

#define SN_des_ofb64            "DES-OFB"
#define LN_des_ofb64            "des-ofb"
#define NID_des_ofb64           45
#define OBJ_des_ofb64           OBJ_algorithm,8L

#define SN_des_cfb64            "DES-CFB"
#define LN_des_cfb64            "des-cfb"
#define NID_des_cfb64           30
#define OBJ_des_cfb64           OBJ_algorithm,9L

#define SN_rsaSignature         "rsaSignature"
#define NID_rsaSignature                377
#define OBJ_rsaSignature                OBJ_algorithm,11L

#define SN_dsa_2                "DSA-old"
#define LN_dsa_2                "dsaEncryption-old"
#define NID_dsa_2               67
#define OBJ_dsa_2               OBJ_algorithm,12L

#define SN_dsaWithSHA           "DSA-SHA"
#define LN_dsaWithSHA           "dsaWithSHA"
#define NID_dsaWithSHA          66
#define OBJ_dsaWithSHA          OBJ_algorithm,13L

#define SN_shaWithRSAEncryption         "RSA-SHA"
#define LN_shaWithRSAEncryption         "shaWithRSAEncryption"
#define NID_shaWithRSAEncryption                42
#define OBJ_shaWithRSAEncryption                OBJ_algorithm,15L

#define SN_des_ede_ecb          "DES-EDE"
#define LN_des_ede_ecb          "des-ede"
#define NID_des_ede_ecb         32
#define OBJ_des_ede_ecb         OBJ_algorithm,17L

#define SN_des_ede3_ecb         "DES-EDE3"
#define LN_des_ede3_ecb         "des-ede3"
#define NID_des_ede3_ecb                33

#define SN_des_ede_cbc          "DES-EDE-CBC"
#define LN_des_ede_cbc          "des-ede-cbc"
#define NID_des_ede_cbc         43

#define SN_des_ede_cfb64                "DES-EDE-CFB"
#define LN_des_ede_cfb64                "des-ede-cfb"
#define NID_des_ede_cfb64               60

#define SN_des_ede3_cfb64               "DES-EDE3-CFB"
#define LN_des_ede3_cfb64               "des-ede3-cfb"
#define NID_des_ede3_cfb64              61

#define SN_des_ede_ofb64                "DES-EDE-OFB"
#define LN_des_ede_ofb64                "des-ede-ofb"
#define NID_des_ede_ofb64               62

#define SN_des_ede3_ofb64               "DES-EDE3-OFB"
#define LN_des_ede3_ofb64               "des-ede3-ofb"
#define NID_des_ede3_ofb64              63

#define SN_desx_cbc             "DESX-CBC"
#define LN_desx_cbc             "desx-cbc"
#define NID_desx_cbc            80

#define SN_sha          "SHA"
#define LN_sha          "sha"
#define NID_sha         41
#define OBJ_sha         OBJ_algorithm,18L

#define SN_sha1         "SHA1"
#define LN_sha1         "sha1"
#define NID_sha1                64
#define OBJ_sha1                OBJ_algorithm,26L

#define SN_dsaWithSHA1_2                "DSA-SHA1-old"
#define LN_dsaWithSHA1_2                "dsaWithSHA1-old"
#define NID_dsaWithSHA1_2               70
#define OBJ_dsaWithSHA1_2               OBJ_algorithm,27L

#define SN_sha1WithRSA          "RSA-SHA1-2"
#define LN_sha1WithRSA          "sha1WithRSA"
#define NID_sha1WithRSA         115
#define OBJ_sha1WithRSA         OBJ_algorithm,29L

#define SN_ripemd160            "RIPEMD160"
#define LN_ripemd160            "ripemd160"
#define NID_ripemd160           117
#define OBJ_ripemd160           1L,3L,36L,3L,2L,1L

#define SN_ripemd160WithRSA             "RSA-RIPEMD160"
#define LN_ripemd160WithRSA             "ripemd160WithRSA"
#define NID_ripemd160WithRSA            119
#define OBJ_ripemd160WithRSA            1L,3L,36L,3L,3L,1L,2L

#define SN_blake2b512           "BLAKE2b512"
#define LN_blake2b512           "blake2b512"
#define NID_blake2b512          1056
#define OBJ_blake2b512          1L,3L,6L,1L,4L,1L,1722L,12L,2L,1L,16L

#define SN_blake2s256           "BLAKE2s256"
#define LN_blake2s256           "blake2s256"
#define NID_blake2s256          1057
#define OBJ_blake2s256          1L,3L,6L,1L,4L,1L,1722L,12L,2L,2L,8L

#define SN_sxnet                "SXNetID"
#define LN_sxnet                "Strong Extranet ID"
#define NID_sxnet               143
#define OBJ_sxnet               1L,3L,101L,1L,4L,1L

#define SN_X500         "X500"
#define LN_X500         "directory services (X.500)"
#define NID_X500                11
#define OBJ_X500                2L,5L

#define SN_X509         "X509"
#define NID_X509                12
#define OBJ_X509                OBJ_X500,4L

#define SN_commonName           "CN"
#define LN_commonName           "commonName"
#define NID_commonName          13
#define OBJ_commonName          OBJ_X509,3L

#define SN_surname              "SN"
#define LN_surname              "surname"
#define NID_surname             100
#define OBJ_surname             OBJ_X509,4L

#define LN_serialNumber         "serialNumber"
#define NID_serialNumber                105
#define OBJ_serialNumber                OBJ_X509,5L

#define SN_countryName          "C"
#define LN_countryName          "countryName"
#define NID_countryName         14
#define OBJ_countryName         OBJ_X509,6L

#define SN_localityName         "L"
#define LN_localityName         "localityName"
#define NID_localityName                15
#define OBJ_localityName                OBJ_X509,7L

#define SN_stateOrProvinceName          "ST"
#define LN_stateOrProvinceName          "stateOrProvinceName"
#define NID_stateOrProvinceName         16
#define OBJ_stateOrProvinceName         OBJ_X509,8L

#define SN_streetAddress                "street"
#define LN_streetAddress                "streetAddress"
#define NID_streetAddress               660
#define OBJ_streetAddress               OBJ_X509,9L

#define SN_organizationName             "O"
#define LN_organizationName             "organizationName"
#define NID_organizationName            17
#define OBJ_organizationName            OBJ_X509,10L

#define SN_organizationalUnitName               "OU"
#define LN_organizationalUnitName               "organizationalUnitName"
#define NID_organizationalUnitName              18
#define OBJ_organizationalUnitName              OBJ_X509,11L

#define SN_title                "title"
#define LN_title                "title"
#define NID_title               106
#define OBJ_title               OBJ_X509,12L

#define LN_description          "description"
#define NID_description         107
#define OBJ_description         OBJ_X509,13L

#define LN_searchGuide          "searchGuide"
#define NID_searchGuide         859
#define OBJ_searchGuide         OBJ_X509,14L

#define LN_businessCategory             "businessCategory"
#define NID_businessCategory            860
#define OBJ_businessCategory            OBJ_X509,15L

#define LN_postalAddress                "postalAddress"
#define NID_postalAddress               861
#define OBJ_postalAddress               OBJ_X509,16L

#define LN_postalCode           "postalCode"
#define NID_postalCode          661
#define OBJ_postalCode          OBJ_X509,17L

#define LN_postOfficeBox                "postOfficeBox"
#define NID_postOfficeBox               862
#define OBJ_postOfficeBox               OBJ_X509,18L

#define LN_physicalDeliveryOfficeName           "physicalDeliveryOfficeName"
#define NID_physicalDeliveryOfficeName          863
#define OBJ_physicalDeliveryOfficeName          OBJ_X509,19L

#define LN_telephoneNumber              "telephoneNumber"
#define NID_telephoneNumber             864
#define OBJ_telephoneNumber             OBJ_X509,20L

#define LN_telexNumber          "telexNumber"
#define NID_telexNumber         865
#define OBJ_telexNumber         OBJ_X509,21L

#define LN_teletexTerminalIdentifier            "teletexTerminalIdentifier"
#define NID_teletexTerminalIdentifier           866
#define OBJ_teletexTerminalIdentifier           OBJ_X509,22L

#define LN_facsimileTelephoneNumber             "facsimileTelephoneNumber"
#define NID_facsimileTelephoneNumber            867
#define OBJ_facsimileTelephoneNumber            OBJ_X509,23L

#define LN_x121Address          "x121Address"
#define NID_x121Address         868
#define OBJ_x121Address         OBJ_X509,24L

#define LN_internationaliSDNNumber              "internationaliSDNNumber"
#define NID_internationaliSDNNumber             869
#define OBJ_internationaliSDNNumber             OBJ_X509,25L

#define LN_registeredAddress            "registeredAddress"
#define NID_registeredAddress           870
#define OBJ_registeredAddress           OBJ_X509,26L

#define LN_destinationIndicator         "destinationIndicator"
#define NID_destinationIndicator                871
#define OBJ_destinationIndicator                OBJ_X509,27L

#define LN_preferredDeliveryMethod              "preferredDeliveryMethod"
#define NID_preferredDeliveryMethod             872
#define OBJ_preferredDeliveryMethod             OBJ_X509,28L

#define LN_presentationAddress          "presentationAddress"
#define NID_presentationAddress         873
#define OBJ_presentationAddress         OBJ_X509,29L

#define LN_supportedApplicationContext          "supportedApplicationContext"
#define NID_supportedApplicationContext         874
#define OBJ_supportedApplicationContext         OBJ_X509,30L

#define SN_member               "member"
#define NID_member              875
#define OBJ_member              OBJ_X509,31L

#define SN_owner                "owner"
#define NID_owner               876
#define OBJ_owner               OBJ_X509,32L

#define LN_roleOccupant         "roleOccupant"
#define NID_roleOccupant                877
#define OBJ_roleOccupant                OBJ_X509,33L

#define SN_seeAlso              "seeAlso"
#define NID_seeAlso             878
#define OBJ_seeAlso             OBJ_X509,34L

#define LN_userPassword         "userPassword"
#define NID_userPassword                879
#define OBJ_userPassword                OBJ_X509,35L

#define LN_userCertificate              "userCertificate"
#define NID_userCertificate             880
#define OBJ_userCertificate             OBJ_X509,36L

#define LN_cACertificate                "cACertificate"
#define NID_cACertificate               881
#define OBJ_cACertificate               OBJ_X509,37L

#define LN_authorityRevocationList              "authorityRevocationList"
#define NID_authorityRevocationList             882
#define OBJ_authorityRevocationList             OBJ_X509,38L

#define LN_certificateRevocationList            "certificateRevocationList"
#define NID_certificateRevocationList           883
#define OBJ_certificateRevocationList           OBJ_X509,39L

#define LN_crossCertificatePair         "crossCertificatePair"
#define NID_crossCertificatePair                884
#define OBJ_crossCertificatePair                OBJ_X509,40L

#define SN_name         "name"
#define LN_name         "name"
#define NID_name                173
#define OBJ_name                OBJ_X509,41L

#define SN_givenName            "GN"
#define LN_givenName            "givenName"
#define NID_givenName           99
#define OBJ_givenName           OBJ_X509,42L

#define SN_initials             "initials"
#define LN_initials             "initials"
#define NID_initials            101
#define OBJ_initials            OBJ_X509,43L

#define LN_generationQualifier          "generationQualifier"
#define NID_generationQualifier         509
#define OBJ_generationQualifier         OBJ_X509,44L

#define LN_x500UniqueIdentifier         "x500UniqueIdentifier"
#define NID_x500UniqueIdentifier                503
#define OBJ_x500UniqueIdentifier                OBJ_X509,45L

#define SN_dnQualifier          "dnQualifier"
#define LN_dnQualifier          "dnQualifier"
#define NID_dnQualifier         174
#define OBJ_dnQualifier         OBJ_X509,46L

#define LN_enhancedSearchGuide          "enhancedSearchGuide"
#define NID_enhancedSearchGuide         885
#define OBJ_enhancedSearchGuide         OBJ_X509,47L

#define LN_protocolInformation          "protocolInformation"
#define NID_protocolInformation         886
#define OBJ_protocolInformation         OBJ_X509,48L

#define LN_distinguishedName            "distinguishedName"
#define NID_distinguishedName           887
#define OBJ_distinguishedName           OBJ_X509,49L

#define LN_uniqueMember         "uniqueMember"
#define NID_uniqueMember                888
#define OBJ_uniqueMember                OBJ_X509,50L

#define LN_houseIdentifier              "houseIdentifier"
#define NID_houseIdentifier             889
#define OBJ_houseIdentifier             OBJ_X509,51L

#define LN_supportedAlgorithms          "supportedAlgorithms"
#define NID_supportedAlgorithms         890
#define OBJ_supportedAlgorithms         OBJ_X509,52L

#define LN_deltaRevocationList          "deltaRevocationList"
#define NID_deltaRevocationList         891
#define OBJ_deltaRevocationList         OBJ_X509,53L

#define SN_dmdName              "dmdName"
#define NID_dmdName             892
#define OBJ_dmdName             OBJ_X509,54L

#define LN_pseudonym            "pseudonym"
#define NID_pseudonym           510
#define OBJ_pseudonym           OBJ_X509,65L

#define SN_role         "role"
#define LN_role         "role"
#define NID_role                400
#define OBJ_role                OBJ_X509,72L

#define LN_organizationIdentifier               "organizationIdentifier"
#define NID_organizationIdentifier              1089
#define OBJ_organizationIdentifier              OBJ_X509,97L

#define SN_countryCode3c                "c3"
#define LN_countryCode3c                "countryCode3c"
#define NID_countryCode3c               1090
#define OBJ_countryCode3c               OBJ_X509,98L

#define SN_countryCode3n                "n3"
#define LN_countryCode3n                "countryCode3n"
#define NID_countryCode3n               1091
#define OBJ_countryCode3n               OBJ_X509,99L

#define LN_dnsName              "dnsName"
#define NID_dnsName             1092
#define OBJ_dnsName             OBJ_X509,100L

#define SN_X500algorithms               "X500algorithms"
#define LN_X500algorithms               "directory services - algorithms"
#define NID_X500algorithms              378
#define OBJ_X500algorithms              OBJ_X500,8L

#define SN_rsa          "RSA"
#define LN_rsa          "rsa"
#define NID_rsa         19
#define OBJ_rsa         OBJ_X500algorithms,1L,1L

#define SN_mdc2WithRSA          "RSA-MDC2"
#define LN_mdc2WithRSA          "mdc2WithRSA"
#define NID_mdc2WithRSA         96
#define OBJ_mdc2WithRSA         OBJ_X500algorithms,3L,100L

#define SN_mdc2         "MDC2"
#define LN_mdc2         "mdc2"
#define NID_mdc2                95
#define OBJ_mdc2                OBJ_X500algorithms,3L,101L

#define SN_id_ce                "id-ce"
#define NID_id_ce               81
#define OBJ_id_ce               OBJ_X500,29L

#define SN_subject_directory_attributes         "subjectDirectoryAttributes"
#define LN_subject_directory_attributes         "X509v3 Subject Directory Attributes"
#define NID_subject_directory_attributes                769
#define OBJ_subject_directory_attributes                OBJ_id_ce,9L

#define SN_subject_key_identifier               "subjectKeyIdentifier"
#define LN_subject_key_identifier               "X509v3 Subject Key Identifier"
#define NID_subject_key_identifier              82
#define OBJ_subject_key_identifier              OBJ_id_ce,14L

#define SN_key_usage            "keyUsage"
#define LN_key_usage            "X509v3 Key Usage"
#define NID_key_usage           83
#define OBJ_key_usage           OBJ_id_ce,15L

#define SN_private_key_usage_period             "privateKeyUsagePeriod"
#define LN_private_key_usage_period             "X509v3 Private Key Usage Period"
#define NID_private_key_usage_period            84
#define OBJ_private_key_usage_period            OBJ_id_ce,16L

#define SN_subject_alt_name             "subjectAltName"
#define LN_subject_alt_name             "X509v3 Subject Alternative Name"
#define NID_subject_alt_name            85
#define OBJ_subject_alt_name            OBJ_id_ce,17L

#define SN_issuer_alt_name              "issuerAltName"
#define LN_issuer_alt_name              "X509v3 Issuer Alternative Name"
#define NID_issuer_alt_name             86
#define OBJ_issuer_alt_name             OBJ_id_ce,18L

#define SN_basic_constraints            "basicConstraints"
#define LN_basic_constraints            "X509v3 Basic Constraints"
#define NID_basic_constraints           87
#define OBJ_basic_constraints           OBJ_id_ce,19L

#define SN_crl_number           "crlNumber"
#define LN_crl_number           "X509v3 CRL Number"
#define NID_crl_number          88
#define OBJ_crl_number          OBJ_id_ce,20L

#define SN_crl_reason           "CRLReason"
#define LN_crl_reason           "X509v3 CRL Reason Code"
#define NID_crl_reason          141
#define OBJ_crl_reason          OBJ_id_ce,21L

#define SN_invalidity_date              "invalidityDate"
#define LN_invalidity_date              "Invalidity Date"
#define NID_invalidity_date             142
#define OBJ_invalidity_date             OBJ_id_ce,24L

#define SN_delta_crl            "deltaCRL"
#define LN_delta_crl            "X509v3 Delta CRL Indicator"
#define NID_delta_crl           140
#define OBJ_delta_crl           OBJ_id_ce,27L

#define SN_issuing_distribution_point           "issuingDistributionPoint"
#define LN_issuing_distribution_point           "X509v3 Issuing Distribution Point"
#define NID_issuing_distribution_point          770
#define OBJ_issuing_distribution_point          OBJ_id_ce,28L

#define SN_certificate_issuer           "certificateIssuer"
#define LN_certificate_issuer           "X509v3 Certificate Issuer"
#define NID_certificate_issuer          771
#define OBJ_certificate_issuer          OBJ_id_ce,29L

#define SN_name_constraints             "nameConstraints"
#define LN_name_constraints             "X509v3 Name Constraints"
#define NID_name_constraints            666
#define OBJ_name_constraints            OBJ_id_ce,30L

#define SN_crl_distribution_points              "crlDistributionPoints"
#define LN_crl_distribution_points              "X509v3 CRL Distribution Points"
#define NID_crl_distribution_points             103
#define OBJ_crl_distribution_points             OBJ_id_ce,31L

#define SN_certificate_policies         "certificatePolicies"
#define LN_certificate_policies         "X509v3 Certificate Policies"
#define NID_certificate_policies                89
#define OBJ_certificate_policies                OBJ_id_ce,32L

#define SN_any_policy           "anyPolicy"
#define LN_any_policy           "X509v3 Any Policy"
#define NID_any_policy          746
#define OBJ_any_policy          OBJ_certificate_policies,0L

#define SN_policy_mappings              "policyMappings"
#define LN_policy_mappings              "X509v3 Policy Mappings"
#define NID_policy_mappings             747
#define OBJ_policy_mappings             OBJ_id_ce,33L

#define SN_authority_key_identifier             "authorityKeyIdentifier"
#define LN_authority_key_identifier             "X509v3 Authority Key Identifier"
#define NID_authority_key_identifier            90
#define OBJ_authority_key_identifier            OBJ_id_ce,35L

#define SN_policy_constraints           "policyConstraints"
#define LN_policy_constraints           "X509v3 Policy Constraints"
#define NID_policy_constraints          401
#define OBJ_policy_constraints          OBJ_id_ce,36L

#define SN_ext_key_usage                "extendedKeyUsage"
#define LN_ext_key_usage                "X509v3 Extended Key Usage"
#define NID_ext_key_usage               126
#define OBJ_ext_key_usage               OBJ_id_ce,37L

#define SN_freshest_crl         "freshestCRL"
#define LN_freshest_crl         "X509v3 Freshest CRL"
#define NID_freshest_crl                857
#define OBJ_freshest_crl                OBJ_id_ce,46L

#define SN_inhibit_any_policy           "inhibitAnyPolicy"
#define LN_inhibit_any_policy           "X509v3 Inhibit Any Policy"
#define NID_inhibit_any_policy          748
#define OBJ_inhibit_any_policy          OBJ_id_ce,54L

#define SN_target_information           "targetInformation"
#define LN_target_information           "X509v3 AC Targeting"
#define NID_target_information          402
#define OBJ_target_information          OBJ_id_ce,55L

#define SN_no_rev_avail         "noRevAvail"
#define LN_no_rev_avail         "X509v3 No Revocation Available"
#define NID_no_rev_avail                403
#define OBJ_no_rev_avail                OBJ_id_ce,56L

#define SN_anyExtendedKeyUsage          "anyExtendedKeyUsage"
#define LN_anyExtendedKeyUsage          "Any Extended Key Usage"
#define NID_anyExtendedKeyUsage         910
#define OBJ_anyExtendedKeyUsage         OBJ_ext_key_usage,0L

#define SN_netscape             "Netscape"
#define LN_netscape             "Netscape Communications Corp."
#define NID_netscape            57
#define OBJ_netscape            2L,16L,840L,1L,113730L

#define SN_netscape_cert_extension              "nsCertExt"
#define LN_netscape_cert_extension              "Netscape Certificate Extension"
#define NID_netscape_cert_extension             58
#define OBJ_netscape_cert_extension             OBJ_netscape,1L

#define SN_netscape_data_type           "nsDataType"
#define LN_netscape_data_type           "Netscape Data Type"
#define NID_netscape_data_type          59
#define OBJ_netscape_data_type          OBJ_netscape,2L

#define SN_netscape_cert_type           "nsCertType"
#define LN_netscape_cert_type           "Netscape Cert Type"
#define NID_netscape_cert_type          71
#define OBJ_netscape_cert_type          OBJ_netscape_cert_extension,1L

#define SN_netscape_base_url            "nsBaseUrl"
#define LN_netscape_base_url            "Netscape Base Url"
#define NID_netscape_base_url           72
#define OBJ_netscape_base_url           OBJ_netscape_cert_extension,2L

#define SN_netscape_revocation_url              "nsRevocationUrl"
#define LN_netscape_revocation_url              "Netscape Revocation Url"
#define NID_netscape_revocation_url             73
#define OBJ_netscape_revocation_url             OBJ_netscape_cert_extension,3L

#define SN_netscape_ca_revocation_url           "nsCaRevocationUrl"
#define LN_netscape_ca_revocation_url           "Netscape CA Revocation Url"
#define NID_netscape_ca_revocation_url          74
#define OBJ_netscape_ca_revocation_url          OBJ_netscape_cert_extension,4L

#define SN_netscape_renewal_url         "nsRenewalUrl"
#define LN_netscape_renewal_url         "Netscape Renewal Url"
#define NID_netscape_renewal_url                75
#define OBJ_netscape_renewal_url                OBJ_netscape_cert_extension,7L

#define SN_netscape_ca_policy_url               "nsCaPolicyUrl"
#define LN_netscape_ca_policy_url               "Netscape CA Policy Url"
#define NID_netscape_ca_policy_url              76
#define OBJ_netscape_ca_policy_url              OBJ_netscape_cert_extension,8L

#define SN_netscape_ssl_server_name             "nsSslServerName"
#define LN_netscape_ssl_server_name             "Netscape SSL Server Name"
#define NID_netscape_ssl_server_name            77
#define OBJ_netscape_ssl_server_name            OBJ_netscape_cert_extension,12L

#define SN_netscape_comment             "nsComment"
#define LN_netscape_comment             "Netscape Comment"
#define NID_netscape_comment            78
#define OBJ_netscape_comment            OBJ_netscape_cert_extension,13L

#define SN_netscape_cert_sequence               "nsCertSequence"
#define LN_netscape_cert_sequence               "Netscape Certificate Sequence"
#define NID_netscape_cert_sequence              79
#define OBJ_netscape_cert_sequence              OBJ_netscape_data_type,5L

#define SN_ns_sgc               "nsSGC"
#define LN_ns_sgc               "Netscape Server Gated Crypto"
#define NID_ns_sgc              139
#define OBJ_ns_sgc              OBJ_netscape,4L,1L

#define SN_org          "ORG"
#define LN_org          "org"
#define NID_org         379
#define OBJ_org         OBJ_iso,3L

#define SN_dod          "DOD"
#define LN_dod          "dod"
#define NID_dod         380
#define OBJ_dod         OBJ_org,6L

#define SN_iana         "IANA"
#define LN_iana         "iana"
#define NID_iana                381
#define OBJ_iana                OBJ_dod,1L

#define OBJ_internet            OBJ_iana

#define SN_Directory            "directory"
#define LN_Directory            "Directory"
#define NID_Directory           382
#define OBJ_Directory           OBJ_internet,1L

#define SN_Management           "mgmt"
#define LN_Management           "Management"
#define NID_Management          383
#define OBJ_Management          OBJ_internet,2L

#define SN_Experimental         "experimental"
#define LN_Experimental         "Experimental"
#define NID_Experimental                384
#define OBJ_Experimental                OBJ_internet,3L

#define SN_Private              "private"
#define LN_Private              "Private"
#define NID_Private             385
#define OBJ_Private             OBJ_internet,4L

#define SN_Security             "security"
#define LN_Security             "Security"
#define NID_Security            386
#define OBJ_Security            OBJ_internet,5L

#define SN_SNMPv2               "snmpv2"
#define LN_SNMPv2               "SNMPv2"
#define NID_SNMPv2              387
#define OBJ_SNMPv2              OBJ_internet,6L

#define LN_Mail         "Mail"
#define NID_Mail                388
#define OBJ_Mail                OBJ_internet,7L

#define SN_Enterprises          "enterprises"
#define LN_Enterprises          "Enterprises"
#define NID_Enterprises         389
#define OBJ_Enterprises         OBJ_Private,1L

#define SN_dcObject             "dcobject"
#define LN_dcObject             "dcObject"
#define NID_dcObject            390
#define OBJ_dcObject            OBJ_Enterprises,1466L,344L

#define SN_mime_mhs             "mime-mhs"
#define LN_mime_mhs             "MIME MHS"
#define NID_mime_mhs            504
#define OBJ_mime_mhs            OBJ_Mail,1L

#define SN_mime_mhs_headings            "mime-mhs-headings"
#define LN_mime_mhs_headings            "mime-mhs-headings"
#define NID_mime_mhs_headings           505
#define OBJ_mime_mhs_headings           OBJ_mime_mhs,1L

#define SN_mime_mhs_bodies              "mime-mhs-bodies"
#define LN_mime_mhs_bodies              "mime-mhs-bodies"
#define NID_mime_mhs_bodies             506
#define OBJ_mime_mhs_bodies             OBJ_mime_mhs,2L

#define SN_id_hex_partial_message               "id-hex-partial-message"
#define LN_id_hex_partial_message               "id-hex-partial-message"
#define NID_id_hex_partial_message              507
#define OBJ_id_hex_partial_message              OBJ_mime_mhs_headings,1L

#define SN_id_hex_multipart_message             "id-hex-multipart-message"
#define LN_id_hex_multipart_message             "id-hex-multipart-message"
#define NID_id_hex_multipart_message            508
#define OBJ_id_hex_multipart_message            OBJ_mime_mhs_headings,2L

#define SN_zlib_compression             "ZLIB"
#define LN_zlib_compression             "zlib compression"
#define NID_zlib_compression            125
#define OBJ_zlib_compression            OBJ_id_smime_alg,8L

#define OBJ_csor                2L,16L,840L,1L,101L,3L

#define OBJ_nistAlgorithms              OBJ_csor,4L

#define OBJ_aes         OBJ_nistAlgorithms,1L

#define SN_aes_128_ecb          "AES-128-ECB"
#define LN_aes_128_ecb          "aes-128-ecb"
#define NID_aes_128_ecb         418
#define OBJ_aes_128_ecb         OBJ_aes,1L

#define SN_aes_128_cbc          "AES-128-CBC"
#define LN_aes_128_cbc          "aes-128-cbc"
#define NID_aes_128_cbc         419
#define OBJ_aes_128_cbc         OBJ_aes,2L

#define SN_aes_128_ofb128               "AES-128-OFB"
#define LN_aes_128_ofb128               "aes-128-ofb"
#define NID_aes_128_ofb128              420
#define OBJ_aes_128_ofb128              OBJ_aes,3L

#define SN_aes_128_cfb128               "AES-128-CFB"
#define LN_aes_128_cfb128               "aes-128-cfb"
#define NID_aes_128_cfb128              421
#define OBJ_aes_128_cfb128              OBJ_aes,4L

#define SN_id_aes128_wrap               "id-aes128-wrap"
#define NID_id_aes128_wrap              788
#define OBJ_id_aes128_wrap              OBJ_aes,5L

#define SN_aes_128_gcm          "id-aes128-GCM"
#define LN_aes_128_gcm          "aes-128-gcm"
#define NID_aes_128_gcm         895
#define OBJ_aes_128_gcm         OBJ_aes,6L

#define SN_aes_128_ccm          "id-aes128-CCM"
#define LN_aes_128_ccm          "aes-128-ccm"
#define NID_aes_128_ccm         896
#define OBJ_aes_128_ccm         OBJ_aes,7L

#define SN_id_aes128_wrap_pad           "id-aes128-wrap-pad"
#define NID_id_aes128_wrap_pad          897
#define OBJ_id_aes128_wrap_pad          OBJ_aes,8L

#define SN_aes_192_ecb          "AES-192-ECB"
#define LN_aes_192_ecb          "aes-192-ecb"
#define NID_aes_192_ecb         422
#define OBJ_aes_192_ecb         OBJ_aes,21L

#define SN_aes_192_cbc          "AES-192-CBC"
#define LN_aes_192_cbc          "aes-192-cbc"
#define NID_aes_192_cbc         423
#define OBJ_aes_192_cbc         OBJ_aes,22L

#define SN_aes_192_ofb128               "AES-192-OFB"
#define LN_aes_192_ofb128               "aes-192-ofb"
#define NID_aes_192_ofb128              424
#define OBJ_aes_192_ofb128              OBJ_aes,23L

#define SN_aes_192_cfb128               "AES-192-CFB"
#define LN_aes_192_cfb128               "aes-192-cfb"
#define NID_aes_192_cfb128              425
#define OBJ_aes_192_cfb128              OBJ_aes,24L

#define SN_id_aes192_wrap               "id-aes192-wrap"
#define NID_id_aes192_wrap              789
#define OBJ_id_aes192_wrap              OBJ_aes,25L

#define SN_aes_192_gcm          "id-aes192-GCM"
#define LN_aes_192_gcm          "aes-192-gcm"
#define NID_aes_192_gcm         898
#define OBJ_aes_192_gcm         OBJ_aes,26L

#define SN_aes_192_ccm          "id-aes192-CCM"
#define LN_aes_192_ccm          "aes-192-ccm"
#define NID_aes_192_ccm         899
#define OBJ_aes_192_ccm         OBJ_aes,27L

#define SN_id_aes192_wrap_pad           "id-aes192-wrap-pad"
#define NID_id_aes192_wrap_pad          900
#define OBJ_id_aes192_wrap_pad          OBJ_aes,28L

#define SN_aes_256_ecb          "AES-256-ECB"
#define LN_aes_256_ecb          "aes-256-ecb"
#define NID_aes_256_ecb         426
#define OBJ_aes_256_ecb         OBJ_aes,41L

#define SN_aes_256_cbc          "AES-256-CBC"
#define LN_aes_256_cbc          "aes-256-cbc"
#define NID_aes_256_cbc         427
#define OBJ_aes_256_cbc         OBJ_aes,42L

#define SN_aes_256_ofb128               "AES-256-OFB"
#define LN_aes_256_ofb128               "aes-256-ofb"
#define NID_aes_256_ofb128              428
#define OBJ_aes_256_ofb128              OBJ_aes,43L

#define SN_aes_256_cfb128               "AES-256-CFB"
#define LN_aes_256_cfb128               "aes-256-cfb"
#define NID_aes_256_cfb128              429
#define OBJ_aes_256_cfb128              OBJ_aes,44L

#define SN_id_aes256_wrap               "id-aes256-wrap"
#define NID_id_aes256_wrap              790
#define OBJ_id_aes256_wrap              OBJ_aes,45L

#define SN_aes_256_gcm          "id-aes256-GCM"
#define LN_aes_256_gcm          "aes-256-gcm"
#define NID_aes_256_gcm         901
#define OBJ_aes_256_gcm         OBJ_aes,46L

#define SN_aes_256_ccm          "id-aes256-CCM"
#define LN_aes_256_ccm          "aes-256-ccm"
#define NID_aes_256_ccm         902
#define OBJ_aes_256_ccm         OBJ_aes,47L

#define SN_id_aes256_wrap_pad           "id-aes256-wrap-pad"
#define NID_id_aes256_wrap_pad          903
#define OBJ_id_aes256_wrap_pad          OBJ_aes,48L

#define SN_aes_128_xts          "AES-128-XTS"
#define LN_aes_128_xts          "aes-128-xts"
#define NID_aes_128_xts         913
#define OBJ_aes_128_xts         OBJ_ieee_siswg,0L,1L,1L

#define SN_aes_256_xts          "AES-256-XTS"
#define LN_aes_256_xts          "aes-256-xts"
#define NID_aes_256_xts         914
#define OBJ_aes_256_xts         OBJ_ieee_siswg,0L,1L,2L

#define SN_aes_128_cfb1         "AES-128-CFB1"
#define LN_aes_128_cfb1         "aes-128-cfb1"
#define NID_aes_128_cfb1                650

#define SN_aes_192_cfb1         "AES-192-CFB1"
#define LN_aes_192_cfb1         "aes-192-cfb1"
#define NID_aes_192_cfb1                651

#define SN_aes_256_cfb1         "AES-256-CFB1"
#define LN_aes_256_cfb1         "aes-256-cfb1"
#define NID_aes_256_cfb1                652

#define SN_aes_128_cfb8         "AES-128-CFB8"
#define LN_aes_128_cfb8         "aes-128-cfb8"
#define NID_aes_128_cfb8                653

#define SN_aes_192_cfb8         "AES-192-CFB8"
#define LN_aes_192_cfb8         "aes-192-cfb8"
#define NID_aes_192_cfb8                654

#define SN_aes_256_cfb8         "AES-256-CFB8"
#define LN_aes_256_cfb8         "aes-256-cfb8"
#define NID_aes_256_cfb8                655

#define SN_aes_128_ctr          "AES-128-CTR"
#define LN_aes_128_ctr          "aes-128-ctr"
#define NID_aes_128_ctr         904

#define SN_aes_192_ctr          "AES-192-CTR"
#define LN_aes_192_ctr          "aes-192-ctr"
#define NID_aes_192_ctr         905

#define SN_aes_256_ctr          "AES-256-CTR"
#define LN_aes_256_ctr          "aes-256-ctr"
#define NID_aes_256_ctr         906

#define SN_aes_128_ocb          "AES-128-OCB"
#define LN_aes_128_ocb          "aes-128-ocb"
#define NID_aes_128_ocb         958

#define SN_aes_192_ocb          "AES-192-OCB"
#define LN_aes_192_ocb          "aes-192-ocb"
#define NID_aes_192_ocb         959

#define SN_aes_256_ocb          "AES-256-OCB"
#define LN_aes_256_ocb          "aes-256-ocb"
#define NID_aes_256_ocb         960

#define SN_des_cfb1             "DES-CFB1"
#define LN_des_cfb1             "des-cfb1"
#define NID_des_cfb1            656

#define SN_des_cfb8             "DES-CFB8"
#define LN_des_cfb8             "des-cfb8"
#define NID_des_cfb8            657

#define SN_des_ede3_cfb1                "DES-EDE3-CFB1"
#define LN_des_ede3_cfb1                "des-ede3-cfb1"
#define NID_des_ede3_cfb1               658

#define SN_des_ede3_cfb8                "DES-EDE3-CFB8"
#define LN_des_ede3_cfb8                "des-ede3-cfb8"
#define NID_des_ede3_cfb8               659

#define OBJ_nist_hashalgs               OBJ_nistAlgorithms,2L

#define SN_sha256               "SHA256"
#define LN_sha256               "sha256"
#define NID_sha256              672
#define OBJ_sha256              OBJ_nist_hashalgs,1L

#define SN_sha384               "SHA384"
#define LN_sha384               "sha384"
#define NID_sha384              673
#define OBJ_sha384              OBJ_nist_hashalgs,2L

#define SN_sha512               "SHA512"
#define LN_sha512               "sha512"
#define NID_sha512              674
#define OBJ_sha512              OBJ_nist_hashalgs,3L

#define SN_sha224               "SHA224"
#define LN_sha224               "sha224"
#define NID_sha224              675
#define OBJ_sha224              OBJ_nist_hashalgs,4L

#define SN_sha512_224           "SHA512-224"
#define LN_sha512_224           "sha512-224"
#define NID_sha512_224          1094
#define OBJ_sha512_224          OBJ_nist_hashalgs,5L

#define SN_sha512_256           "SHA512-256"
#define LN_sha512_256           "sha512-256"
#define NID_sha512_256          1095
#define OBJ_sha512_256          OBJ_nist_hashalgs,6L

#define SN_sha3_224             "SHA3-224"
#define LN_sha3_224             "sha3-224"
#define NID_sha3_224            1096
#define OBJ_sha3_224            OBJ_nist_hashalgs,7L

#define SN_sha3_256             "SHA3-256"
#define LN_sha3_256             "sha3-256"
#define NID_sha3_256            1097
#define OBJ_sha3_256            OBJ_nist_hashalgs,8L

#define SN_sha3_384             "SHA3-384"
#define LN_sha3_384             "sha3-384"
#define NID_sha3_384            1098
#define OBJ_sha3_384            OBJ_nist_hashalgs,9L

#define SN_sha3_512             "SHA3-512"
#define LN_sha3_512             "sha3-512"
#define NID_sha3_512            1099
#define OBJ_sha3_512            OBJ_nist_hashalgs,10L

#define SN_shake128             "SHAKE128"
#define LN_shake128             "shake128"
#define NID_shake128            1100
#define OBJ_shake128            OBJ_nist_hashalgs,11L

#define SN_shake256             "SHAKE256"
#define LN_shake256             "shake256"
#define NID_shake256            1101
#define OBJ_shake256            OBJ_nist_hashalgs,12L

#define SN_hmac_sha3_224                "id-hmacWithSHA3-224"
#define LN_hmac_sha3_224                "hmac-sha3-224"
#define NID_hmac_sha3_224               1102
#define OBJ_hmac_sha3_224               OBJ_nist_hashalgs,13L

#define SN_hmac_sha3_256                "id-hmacWithSHA3-256"
#define LN_hmac_sha3_256                "hmac-sha3-256"
#define NID_hmac_sha3_256               1103
#define OBJ_hmac_sha3_256               OBJ_nist_hashalgs,14L

#define SN_hmac_sha3_384                "id-hmacWithSHA3-384"
#define LN_hmac_sha3_384                "hmac-sha3-384"
#define NID_hmac_sha3_384               1104
#define OBJ_hmac_sha3_384               OBJ_nist_hashalgs,15L

#define SN_hmac_sha3_512                "id-hmacWithSHA3-512"
#define LN_hmac_sha3_512                "hmac-sha3-512"
#define NID_hmac_sha3_512               1105
#define OBJ_hmac_sha3_512               OBJ_nist_hashalgs,16L

#define OBJ_dsa_with_sha2               OBJ_nistAlgorithms,3L

#define SN_dsa_with_SHA224              "dsa_with_SHA224"
#define NID_dsa_with_SHA224             802
#define OBJ_dsa_with_SHA224             OBJ_dsa_with_sha2,1L

#define SN_dsa_with_SHA256              "dsa_with_SHA256"
#define NID_dsa_with_SHA256             803
#define OBJ_dsa_with_SHA256             OBJ_dsa_with_sha2,2L

#define OBJ_sigAlgs             OBJ_nistAlgorithms,3L

#define SN_dsa_with_SHA384              "id-dsa-with-sha384"
#define LN_dsa_with_SHA384              "dsa_with_SHA384"
#define NID_dsa_with_SHA384             1106
#define OBJ_dsa_with_SHA384             OBJ_sigAlgs,3L

#define SN_dsa_with_SHA512              "id-dsa-with-sha512"
#define LN_dsa_with_SHA512              "dsa_with_SHA512"
#define NID_dsa_with_SHA512             1107
#define OBJ_dsa_with_SHA512             OBJ_sigAlgs,4L

#define SN_dsa_with_SHA3_224            "id-dsa-with-sha3-224"
#define LN_dsa_with_SHA3_224            "dsa_with_SHA3-224"
#define NID_dsa_with_SHA3_224           1108
#define OBJ_dsa_with_SHA3_224           OBJ_sigAlgs,5L

#define SN_dsa_with_SHA3_256            "id-dsa-with-sha3-256"
#define LN_dsa_with_SHA3_256            "dsa_with_SHA3-256"
#define NID_dsa_with_SHA3_256           1109
#define OBJ_dsa_with_SHA3_256           OBJ_sigAlgs,6L

#define SN_dsa_with_SHA3_384            "id-dsa-with-sha3-384"
#define LN_dsa_with_SHA3_384            "dsa_with_SHA3-384"
#define NID_dsa_with_SHA3_384           1110
#define OBJ_dsa_with_SHA3_384           OBJ_sigAlgs,7L

#define SN_dsa_with_SHA3_512            "id-dsa-with-sha3-512"
#define LN_dsa_with_SHA3_512            "dsa_with_SHA3-512"
#define NID_dsa_with_SHA3_512           1111
#define OBJ_dsa_with_SHA3_512           OBJ_sigAlgs,8L

#define SN_ecdsa_with_SHA3_224          "id-ecdsa-with-sha3-224"
#define LN_ecdsa_with_SHA3_224          "ecdsa_with_SHA3-224"
#define NID_ecdsa_with_SHA3_224         1112
#define OBJ_ecdsa_with_SHA3_224         OBJ_sigAlgs,9L

#define SN_ecdsa_with_SHA3_256          "id-ecdsa-with-sha3-256"
#define LN_ecdsa_with_SHA3_256          "ecdsa_with_SHA3-256"
#define NID_ecdsa_with_SHA3_256         1113
#define OBJ_ecdsa_with_SHA3_256         OBJ_sigAlgs,10L

#define SN_ecdsa_with_SHA3_384          "id-ecdsa-with-sha3-384"
#define LN_ecdsa_with_SHA3_384          "ecdsa_with_SHA3-384"
#define NID_ecdsa_with_SHA3_384         1114
#define OBJ_ecdsa_with_SHA3_384         OBJ_sigAlgs,11L

#define SN_ecdsa_with_SHA3_512          "id-ecdsa-with-sha3-512"
#define LN_ecdsa_with_SHA3_512          "ecdsa_with_SHA3-512"
#define NID_ecdsa_with_SHA3_512         1115
#define OBJ_ecdsa_with_SHA3_512         OBJ_sigAlgs,12L

#define SN_RSA_SHA3_224         "id-rsassa-pkcs1-v1_5-with-sha3-224"
#define LN_RSA_SHA3_224         "RSA-SHA3-224"
#define NID_RSA_SHA3_224                1116
#define OBJ_RSA_SHA3_224                OBJ_sigAlgs,13L

#define SN_RSA_SHA3_256         "id-rsassa-pkcs1-v1_5-with-sha3-256"
#define LN_RSA_SHA3_256         "RSA-SHA3-256"
#define NID_RSA_SHA3_256                1117
#define OBJ_RSA_SHA3_256                OBJ_sigAlgs,14L

#define SN_RSA_SHA3_384         "id-rsassa-pkcs1-v1_5-with-sha3-384"
#define LN_RSA_SHA3_384         "RSA-SHA3-384"
#define NID_RSA_SHA3_384                1118
#define OBJ_RSA_SHA3_384                OBJ_sigAlgs,15L

#define SN_RSA_SHA3_512         "id-rsassa-pkcs1-v1_5-with-sha3-512"
#define LN_RSA_SHA3_512         "RSA-SHA3-512"
#define NID_RSA_SHA3_512                1119
#define OBJ_RSA_SHA3_512                OBJ_sigAlgs,16L

#define SN_hold_instruction_code                "holdInstructionCode"
#define LN_hold_instruction_code                "Hold Instruction Code"
#define NID_hold_instruction_code               430
#define OBJ_hold_instruction_code               OBJ_id_ce,23L

#define OBJ_holdInstruction             OBJ_X9_57,2L

#define SN_hold_instruction_none                "holdInstructionNone"
#define LN_hold_instruction_none                "Hold Instruction None"
#define NID_hold_instruction_none               431
#define OBJ_hold_instruction_none               OBJ_holdInstruction,1L

#define SN_hold_instruction_call_issuer         "holdInstructionCallIssuer"
#define LN_hold_instruction_call_issuer         "Hold Instruction Call Issuer"
#define NID_hold_instruction_call_issuer                432
#define OBJ_hold_instruction_call_issuer                OBJ_holdInstruction,2L

#define SN_hold_instruction_reject              "holdInstructionReject"
#define LN_hold_instruction_reject              "Hold Instruction Reject"
#define NID_hold_instruction_reject             433
#define OBJ_hold_instruction_reject             OBJ_holdInstruction,3L

#define SN_data         "data"
#define NID_data                434
#define OBJ_data                OBJ_itu_t,9L

#define SN_pss          "pss"
#define NID_pss         435
#define OBJ_pss         OBJ_data,2342L

#define SN_ucl          "ucl"
#define NID_ucl         436
#define OBJ_ucl         OBJ_pss,19200300L

#define SN_pilot                "pilot"
#define NID_pilot               437
#define OBJ_pilot               OBJ_ucl,100L

#define LN_pilotAttributeType           "pilotAttributeType"
#define NID_pilotAttributeType          438
#define OBJ_pilotAttributeType          OBJ_pilot,1L

#define LN_pilotAttributeSyntax         "pilotAttributeSyntax"
#define NID_pilotAttributeSyntax                439
#define OBJ_pilotAttributeSyntax                OBJ_pilot,3L

#define LN_pilotObjectClass             "pilotObjectClass"
#define NID_pilotObjectClass            440
#define OBJ_pilotObjectClass            OBJ_pilot,4L

#define LN_pilotGroups          "pilotGroups"
#define NID_pilotGroups         441
#define OBJ_pilotGroups         OBJ_pilot,10L

#define LN_iA5StringSyntax              "iA5StringSyntax"
#define NID_iA5StringSyntax             442
#define OBJ_iA5StringSyntax             OBJ_pilotAttributeSyntax,4L

#define LN_caseIgnoreIA5StringSyntax            "caseIgnoreIA5StringSyntax"
#define NID_caseIgnoreIA5StringSyntax           443
#define OBJ_caseIgnoreIA5StringSyntax           OBJ_pilotAttributeSyntax,5L

#define LN_pilotObject          "pilotObject"
#define NID_pilotObject         444
#define OBJ_pilotObject         OBJ_pilotObjectClass,3L

#define LN_pilotPerson          "pilotPerson"
#define NID_pilotPerson         445
#define OBJ_pilotPerson         OBJ_pilotObjectClass,4L

#define SN_account              "account"
#define NID_account             446
#define OBJ_account             OBJ_pilotObjectClass,5L

#define SN_document             "document"
#define NID_document            447
#define OBJ_document            OBJ_pilotObjectClass,6L

#define SN_room         "room"
#define NID_room                448
#define OBJ_room                OBJ_pilotObjectClass,7L

#define LN_documentSeries               "documentSeries"
#define NID_documentSeries              449
#define OBJ_documentSeries              OBJ_pilotObjectClass,9L

#define SN_Domain               "domain"
#define LN_Domain               "Domain"
#define NID_Domain              392
#define OBJ_Domain              OBJ_pilotObjectClass,13L

#define LN_rFC822localPart              "rFC822localPart"
#define NID_rFC822localPart             450
#define OBJ_rFC822localPart             OBJ_pilotObjectClass,14L

#define LN_dNSDomain            "dNSDomain"
#define NID_dNSDomain           451
#define OBJ_dNSDomain           OBJ_pilotObjectClass,15L

#define LN_domainRelatedObject          "domainRelatedObject"
#define NID_domainRelatedObject         452
#define OBJ_domainRelatedObject         OBJ_pilotObjectClass,17L

#define LN_friendlyCountry              "friendlyCountry"
#define NID_friendlyCountry             453
#define OBJ_friendlyCountry             OBJ_pilotObjectClass,18L

#define LN_simpleSecurityObject         "simpleSecurityObject"
#define NID_simpleSecurityObject                454
#define OBJ_simpleSecurityObject                OBJ_pilotObjectClass,19L

#define LN_pilotOrganization            "pilotOrganization"
#define NID_pilotOrganization           455
#define OBJ_pilotOrganization           OBJ_pilotObjectClass,20L

#define LN_pilotDSA             "pilotDSA"
#define NID_pilotDSA            456
#define OBJ_pilotDSA            OBJ_pilotObjectClass,21L

#define LN_qualityLabelledData          "qualityLabelledData"
#define NID_qualityLabelledData         457
#define OBJ_qualityLabelledData         OBJ_pilotObjectClass,22L

#define SN_userId               "UID"
#define LN_userId               "userId"
#define NID_userId              458
#define OBJ_userId              OBJ_pilotAttributeType,1L

#define LN_textEncodedORAddress         "textEncodedORAddress"
#define NID_textEncodedORAddress                459
#define OBJ_textEncodedORAddress                OBJ_pilotAttributeType,2L

#define SN_rfc822Mailbox                "mail"
#define LN_rfc822Mailbox                "rfc822Mailbox"
#define NID_rfc822Mailbox               460
#define OBJ_rfc822Mailbox               OBJ_pilotAttributeType,3L

#define SN_info         "info"
#define NID_info                461
#define OBJ_info                OBJ_pilotAttributeType,4L

#define LN_favouriteDrink               "favouriteDrink"
#define NID_favouriteDrink              462
#define OBJ_favouriteDrink              OBJ_pilotAttributeType,5L

#define LN_roomNumber           "roomNumber"
#define NID_roomNumber          463
#define OBJ_roomNumber          OBJ_pilotAttributeType,6L

#define SN_photo                "photo"
#define NID_photo               464
#define OBJ_photo               OBJ_pilotAttributeType,7L

#define LN_userClass            "userClass"
#define NID_userClass           465
#define OBJ_userClass           OBJ_pilotAttributeType,8L

#define SN_host         "host"
#define NID_host                466
#define OBJ_host                OBJ_pilotAttributeType,9L

#define SN_manager              "manager"
#define NID_manager             467
#define OBJ_manager             OBJ_pilotAttributeType,10L

#define LN_documentIdentifier           "documentIdentifier"
#define NID_documentIdentifier          468
#define OBJ_documentIdentifier          OBJ_pilotAttributeType,11L

#define LN_documentTitle                "documentTitle"
#define NID_documentTitle               469
#define OBJ_documentTitle               OBJ_pilotAttributeType,12L

#define LN_documentVersion              "documentVersion"
#define NID_documentVersion             470
#define OBJ_documentVersion             OBJ_pilotAttributeType,13L

#define LN_documentAuthor               "documentAuthor"
#define NID_documentAuthor              471
#define OBJ_documentAuthor              OBJ_pilotAttributeType,14L

#define LN_documentLocation             "documentLocation"
#define NID_documentLocation            472
#define OBJ_documentLocation            OBJ_pilotAttributeType,15L

#define LN_homeTelephoneNumber          "homeTelephoneNumber"
#define NID_homeTelephoneNumber         473
#define OBJ_homeTelephoneNumber         OBJ_pilotAttributeType,20L

#define SN_secretary            "secretary"
#define NID_secretary           474
#define OBJ_secretary           OBJ_pilotAttributeType,21L

#define LN_otherMailbox         "otherMailbox"
#define NID_otherMailbox                475
#define OBJ_otherMailbox                OBJ_pilotAttributeType,22L

#define LN_lastModifiedTime             "lastModifiedTime"
#define NID_lastModifiedTime            476
#define OBJ_lastModifiedTime            OBJ_pilotAttributeType,23L

#define LN_lastModifiedBy               "lastModifiedBy"
#define NID_lastModifiedBy              477
#define OBJ_lastModifiedBy              OBJ_pilotAttributeType,24L

#define SN_domainComponent              "DC"
#define LN_domainComponent              "domainComponent"
#define NID_domainComponent             391
#define OBJ_domainComponent             OBJ_pilotAttributeType,25L

#define LN_aRecord              "aRecord"
#define NID_aRecord             478
#define OBJ_aRecord             OBJ_pilotAttributeType,26L

#define LN_pilotAttributeType27         "pilotAttributeType27"
#define NID_pilotAttributeType27                479
#define OBJ_pilotAttributeType27                OBJ_pilotAttributeType,27L

#define LN_mXRecord             "mXRecord"
#define NID_mXRecord            480
#define OBJ_mXRecord            OBJ_pilotAttributeType,28L

#define LN_nSRecord             "nSRecord"
#define NID_nSRecord            481
#define OBJ_nSRecord            OBJ_pilotAttributeType,29L

#define LN_sOARecord            "sOARecord"
#define NID_sOARecord           482
#define OBJ_sOARecord           OBJ_pilotAttributeType,30L

#define LN_cNAMERecord          "cNAMERecord"
#define NID_cNAMERecord         483
#define OBJ_cNAMERecord         OBJ_pilotAttributeType,31L

#define LN_associatedDomain             "associatedDomain"
#define NID_associatedDomain            484
#define OBJ_associatedDomain            OBJ_pilotAttributeType,37L

#define LN_associatedName               "associatedName"
#define NID_associatedName              485
#define OBJ_associatedName              OBJ_pilotAttributeType,38L

#define LN_homePostalAddress            "homePostalAddress"
#define NID_homePostalAddress           486
#define OBJ_homePostalAddress           OBJ_pilotAttributeType,39L

#define LN_personalTitle                "personalTitle"
#define NID_personalTitle               487
#define OBJ_personalTitle               OBJ_pilotAttributeType,40L

#define LN_mobileTelephoneNumber                "mobileTelephoneNumber"
#define NID_mobileTelephoneNumber               488
#define OBJ_mobileTelephoneNumber               OBJ_pilotAttributeType,41L

#define LN_pagerTelephoneNumber         "pagerTelephoneNumber"
#define NID_pagerTelephoneNumber                489
#define OBJ_pagerTelephoneNumber                OBJ_pilotAttributeType,42L

#define LN_friendlyCountryName          "friendlyCountryName"
#define NID_friendlyCountryName         490
#define OBJ_friendlyCountryName         OBJ_pilotAttributeType,43L

#define SN_uniqueIdentifier             "uid"
#define LN_uniqueIdentifier             "uniqueIdentifier"
#define NID_uniqueIdentifier            102
#define OBJ_uniqueIdentifier            OBJ_pilotAttributeType,44L

#define LN_organizationalStatus         "organizationalStatus"
#define NID_organizationalStatus                491
#define OBJ_organizationalStatus                OBJ_pilotAttributeType,45L

#define LN_janetMailbox         "janetMailbox"
#define NID_janetMailbox                492
#define OBJ_janetMailbox                OBJ_pilotAttributeType,46L

#define LN_mailPreferenceOption         "mailPreferenceOption"
#define NID_mailPreferenceOption                493
#define OBJ_mailPreferenceOption                OBJ_pilotAttributeType,47L

#define LN_buildingName         "buildingName"
#define NID_buildingName                494
#define OBJ_buildingName                OBJ_pilotAttributeType,48L

#define LN_dSAQuality           "dSAQuality"
#define NID_dSAQuality          495
#define OBJ_dSAQuality          OBJ_pilotAttributeType,49L

#define LN_singleLevelQuality           "singleLevelQuality"
#define NID_singleLevelQuality          496
#define OBJ_singleLevelQuality          OBJ_pilotAttributeType,50L

#define LN_subtreeMinimumQuality                "subtreeMinimumQuality"
#define NID_subtreeMinimumQuality               497
#define OBJ_subtreeMinimumQuality               OBJ_pilotAttributeType,51L

#define LN_subtreeMaximumQuality                "subtreeMaximumQuality"
#define NID_subtreeMaximumQuality               498
#define OBJ_subtreeMaximumQuality               OBJ_pilotAttributeType,52L

#define LN_personalSignature            "personalSignature"
#define NID_personalSignature           499
#define OBJ_personalSignature           OBJ_pilotAttributeType,53L

#define LN_dITRedirect          "dITRedirect"
#define NID_dITRedirect         500
#define OBJ_dITRedirect         OBJ_pilotAttributeType,54L

#define SN_audio                "audio"
#define NID_audio               501
#define OBJ_audio               OBJ_pilotAttributeType,55L

#define LN_documentPublisher            "documentPublisher"
#define NID_documentPublisher           502
#define OBJ_documentPublisher           OBJ_pilotAttributeType,56L

#define SN_id_set               "id-set"
#define LN_id_set               "Secure Electronic Transactions"
#define NID_id_set              512
#define OBJ_id_set              OBJ_international_organizations,42L

#define SN_set_ctype            "set-ctype"
#define LN_set_ctype            "content types"
#define NID_set_ctype           513
#define OBJ_set_ctype           OBJ_id_set,0L

#define SN_set_msgExt           "set-msgExt"
#define LN_set_msgExt           "message extensions"
#define NID_set_msgExt          514
#define OBJ_set_msgExt          OBJ_id_set,1L

#define SN_set_attr             "set-attr"
#define NID_set_attr            515
#define OBJ_set_attr            OBJ_id_set,3L

#define SN_set_policy           "set-policy"
#define NID_set_policy          516
#define OBJ_set_policy          OBJ_id_set,5L

#define SN_set_certExt          "set-certExt"
#define LN_set_certExt          "certificate extensions"
#define NID_set_certExt         517
#define OBJ_set_certExt         OBJ_id_set,7L

#define SN_set_brand            "set-brand"
#define NID_set_brand           518
#define OBJ_set_brand           OBJ_id_set,8L

#define SN_setct_PANData                "setct-PANData"
#define NID_setct_PANData               519
#define OBJ_setct_PANData               OBJ_set_ctype,0L

#define SN_setct_PANToken               "setct-PANToken"
#define NID_setct_PANToken              520
#define OBJ_setct_PANToken              OBJ_set_ctype,1L

#define SN_setct_PANOnly                "setct-PANOnly"
#define NID_setct_PANOnly               521
#define OBJ_setct_PANOnly               OBJ_set_ctype,2L

#define SN_setct_OIData         "setct-OIData"
#define NID_setct_OIData                522
#define OBJ_setct_OIData                OBJ_set_ctype,3L

#define SN_setct_PI             "setct-PI"
#define NID_setct_PI            523
#define OBJ_setct_PI            OBJ_set_ctype,4L

#define SN_setct_PIData         "setct-PIData"
#define NID_setct_PIData                524
#define OBJ_setct_PIData                OBJ_set_ctype,5L

#define SN_setct_PIDataUnsigned         "setct-PIDataUnsigned"
#define NID_setct_PIDataUnsigned                525
#define OBJ_setct_PIDataUnsigned                OBJ_set_ctype,6L

#define SN_setct_HODInput               "setct-HODInput"
#define NID_setct_HODInput              526
#define OBJ_setct_HODInput              OBJ_set_ctype,7L

#define SN_setct_AuthResBaggage         "setct-AuthResBaggage"
#define NID_setct_AuthResBaggage                527
#define OBJ_setct_AuthResBaggage                OBJ_set_ctype,8L

#define SN_setct_AuthRevReqBaggage              "setct-AuthRevReqBaggage"
#define NID_setct_AuthRevReqBaggage             528
#define OBJ_setct_AuthRevReqBaggage             OBJ_set_ctype,9L

#define SN_setct_AuthRevResBaggage              "setct-AuthRevResBaggage"
#define NID_setct_AuthRevResBaggage             529
#define OBJ_setct_AuthRevResBaggage             OBJ_set_ctype,10L

#define SN_setct_CapTokenSeq            "setct-CapTokenSeq"
#define NID_setct_CapTokenSeq           530
#define OBJ_setct_CapTokenSeq           OBJ_set_ctype,11L

#define SN_setct_PInitResData           "setct-PInitResData"
#define NID_setct_PInitResData          531
#define OBJ_setct_PInitResData          OBJ_set_ctype,12L

#define SN_setct_PI_TBS         "setct-PI-TBS"
#define NID_setct_PI_TBS                532
#define OBJ_setct_PI_TBS                OBJ_set_ctype,13L

#define SN_setct_PResData               "setct-PResData"
#define NID_setct_PResData              533
#define OBJ_setct_PResData              OBJ_set_ctype,14L

#define SN_setct_AuthReqTBS             "setct-AuthReqTBS"
#define NID_setct_AuthReqTBS            534
#define OBJ_setct_AuthReqTBS            OBJ_set_ctype,16L

#define SN_setct_AuthResTBS             "setct-AuthResTBS"
#define NID_setct_AuthResTBS            535
#define OBJ_setct_AuthResTBS            OBJ_set_ctype,17L

#define SN_setct_AuthResTBSX            "setct-AuthResTBSX"
#define NID_setct_AuthResTBSX           536
#define OBJ_setct_AuthResTBSX           OBJ_set_ctype,18L

#define SN_setct_AuthTokenTBS           "setct-AuthTokenTBS"
#define NID_setct_AuthTokenTBS          537
#define OBJ_setct_AuthTokenTBS          OBJ_set_ctype,19L

#define SN_setct_CapTokenData           "setct-CapTokenData"
#define NID_setct_CapTokenData          538
#define OBJ_setct_CapTokenData          OBJ_set_ctype,20L

#define SN_setct_CapTokenTBS            "setct-CapTokenTBS"
#define NID_setct_CapTokenTBS           539
#define OBJ_setct_CapTokenTBS           OBJ_set_ctype,21L

#define SN_setct_AcqCardCodeMsg         "setct-AcqCardCodeMsg"
#define NID_setct_AcqCardCodeMsg                540
#define OBJ_setct_AcqCardCodeMsg                OBJ_set_ctype,22L

#define SN_setct_AuthRevReqTBS          "setct-AuthRevReqTBS"
#define NID_setct_AuthRevReqTBS         541
#define OBJ_setct_AuthRevReqTBS         OBJ_set_ctype,23L

#define SN_setct_AuthRevResData         "setct-AuthRevResData"
#define NID_setct_AuthRevResData                542
#define OBJ_setct_AuthRevResData                OBJ_set_ctype,24L

#define SN_setct_AuthRevResTBS          "setct-AuthRevResTBS"
#define NID_setct_AuthRevResTBS         543
#define OBJ_setct_AuthRevResTBS         OBJ_set_ctype,25L

#define SN_setct_CapReqTBS              "setct-CapReqTBS"
#define NID_setct_CapReqTBS             544
#define OBJ_setct_CapReqTBS             OBJ_set_ctype,26L

#define SN_setct_CapReqTBSX             "setct-CapReqTBSX"
#define NID_setct_CapReqTBSX            545
#define OBJ_setct_CapReqTBSX            OBJ_set_ctype,27L

#define SN_setct_CapResData             "setct-CapResData"
#define NID_setct_CapResData            546
#define OBJ_setct_CapResData            OBJ_set_ctype,28L

#define SN_setct_CapRevReqTBS           "setct-CapRevReqTBS"
#define NID_setct_CapRevReqTBS          547
#define OBJ_setct_CapRevReqTBS          OBJ_set_ctype,29L

#define SN_setct_CapRevReqTBSX          "setct-CapRevReqTBSX"
#define NID_setct_CapRevReqTBSX         548
#define OBJ_setct_CapRevReqTBSX         OBJ_set_ctype,30L

#define SN_setct_CapRevResData          "setct-CapRevResData"
#define NID_setct_CapRevResData         549
#define OBJ_setct_CapRevResData         OBJ_set_ctype,31L

#define SN_setct_CredReqTBS             "setct-CredReqTBS"
#define NID_setct_CredReqTBS            550
#define OBJ_setct_CredReqTBS            OBJ_set_ctype,32L

#define SN_setct_CredReqTBSX            "setct-CredReqTBSX"
#define NID_setct_CredReqTBSX           551
#define OBJ_setct_CredReqTBSX           OBJ_set_ctype,33L

#define SN_setct_CredResData            "setct-CredResData"
#define NID_setct_CredResData           552
#define OBJ_setct_CredResData           OBJ_set_ctype,34L

#define SN_setct_CredRevReqTBS          "setct-CredRevReqTBS"
#define NID_setct_CredRevReqTBS         553
#define OBJ_setct_CredRevReqTBS         OBJ_set_ctype,35L

#define SN_setct_CredRevReqTBSX         "setct-CredRevReqTBSX"
#define NID_setct_CredRevReqTBSX                554
#define OBJ_setct_CredRevReqTBSX                OBJ_set_ctype,36L

#define SN_setct_CredRevResData         "setct-CredRevResData"
#define NID_setct_CredRevResData                555
#define OBJ_setct_CredRevResData                OBJ_set_ctype,37L

#define SN_setct_PCertReqData           "setct-PCertReqData"
#define NID_setct_PCertReqData          556
#define OBJ_setct_PCertReqData          OBJ_set_ctype,38L

#define SN_setct_PCertResTBS            "setct-PCertResTBS"
#define NID_setct_PCertResTBS           557
#define OBJ_setct_PCertResTBS           OBJ_set_ctype,39L

#define SN_setct_BatchAdminReqData              "setct-BatchAdminReqData"
#define NID_setct_BatchAdminReqData             558
#define OBJ_setct_BatchAdminReqData             OBJ_set_ctype,40L

#define SN_setct_BatchAdminResData              "setct-BatchAdminResData"
#define NID_setct_BatchAdminResData             559
#define OBJ_setct_BatchAdminResData             OBJ_set_ctype,41L

#define SN_setct_CardCInitResTBS                "setct-CardCInitResTBS"
#define NID_setct_CardCInitResTBS               560
#define OBJ_setct_CardCInitResTBS               OBJ_set_ctype,42L

#define SN_setct_MeAqCInitResTBS                "setct-MeAqCInitResTBS"
#define NID_setct_MeAqCInitResTBS               561
#define OBJ_setct_MeAqCInitResTBS               OBJ_set_ctype,43L

#define SN_setct_RegFormResTBS          "setct-RegFormResTBS"
#define NID_setct_RegFormResTBS         562
#define OBJ_setct_RegFormResTBS         OBJ_set_ctype,44L

#define SN_setct_CertReqData            "setct-CertReqData"
#define NID_setct_CertReqData           563
#define OBJ_setct_CertReqData           OBJ_set_ctype,45L

#define SN_setct_CertReqTBS             "setct-CertReqTBS"
#define NID_setct_CertReqTBS            564
#define OBJ_setct_CertReqTBS            OBJ_set_ctype,46L

#define SN_setct_CertResData            "setct-CertResData"
#define NID_setct_CertResData           565
#define OBJ_setct_CertResData           OBJ_set_ctype,47L

#define SN_setct_CertInqReqTBS          "setct-CertInqReqTBS"
#define NID_setct_CertInqReqTBS         566
#define OBJ_setct_CertInqReqTBS         OBJ_set_ctype,48L

#define SN_setct_ErrorTBS               "setct-ErrorTBS"
#define NID_setct_ErrorTBS              567
#define OBJ_setct_ErrorTBS              OBJ_set_ctype,49L

#define SN_setct_PIDualSignedTBE                "setct-PIDualSignedTBE"
#define NID_setct_PIDualSignedTBE               568
#define OBJ_setct_PIDualSignedTBE               OBJ_set_ctype,50L

#define SN_setct_PIUnsignedTBE          "setct-PIUnsignedTBE"
#define NID_setct_PIUnsignedTBE         569
#define OBJ_setct_PIUnsignedTBE         OBJ_set_ctype,51L

#define SN_setct_AuthReqTBE             "setct-AuthReqTBE"
#define NID_setct_AuthReqTBE            570
#define OBJ_setct_AuthReqTBE            OBJ_set_ctype,52L

#define SN_setct_AuthResTBE             "setct-AuthResTBE"
#define NID_setct_AuthResTBE            571
#define OBJ_setct_AuthResTBE            OBJ_set_ctype,53L

#define SN_setct_AuthResTBEX            "setct-AuthResTBEX"
#define NID_setct_AuthResTBEX           572
#define OBJ_setct_AuthResTBEX           OBJ_set_ctype,54L

#define SN_setct_AuthTokenTBE           "setct-AuthTokenTBE"
#define NID_setct_AuthTokenTBE          573
#define OBJ_setct_AuthTokenTBE          OBJ_set_ctype,55L

#define SN_setct_CapTokenTBE            "setct-CapTokenTBE"
#define NID_setct_CapTokenTBE           574
#define OBJ_setct_CapTokenTBE           OBJ_set_ctype,56L

#define SN_setct_CapTokenTBEX           "setct-CapTokenTBEX"
#define NID_setct_CapTokenTBEX          575
#define OBJ_setct_CapTokenTBEX          OBJ_set_ctype,57L

#define SN_setct_AcqCardCodeMsgTBE              "setct-AcqCardCodeMsgTBE"
#define NID_setct_AcqCardCodeMsgTBE             576
#define OBJ_setct_AcqCardCodeMsgTBE             OBJ_set_ctype,58L

#define SN_setct_AuthRevReqTBE          "setct-AuthRevReqTBE"
#define NID_setct_AuthRevReqTBE         577
#define OBJ_setct_AuthRevReqTBE         OBJ_set_ctype,59L

#define SN_setct_AuthRevResTBE          "setct-AuthRevResTBE"
#define NID_setct_AuthRevResTBE         578
#define OBJ_setct_AuthRevResTBE         OBJ_set_ctype,60L

#define SN_setct_AuthRevResTBEB         "setct-AuthRevResTBEB"
#define NID_setct_AuthRevResTBEB                579
#define OBJ_setct_AuthRevResTBEB                OBJ_set_ctype,61L

#define SN_setct_CapReqTBE              "setct-CapReqTBE"
#define NID_setct_CapReqTBE             580
#define OBJ_setct_CapReqTBE             OBJ_set_ctype,62L

#define SN_setct_CapReqTBEX             "setct-CapReqTBEX"
#define NID_setct_CapReqTBEX            581
#define OBJ_setct_CapReqTBEX            OBJ_set_ctype,63L

#define SN_setct_CapResTBE              "setct-CapResTBE"
#define NID_setct_CapResTBE             582
#define OBJ_setct_CapResTBE             OBJ_set_ctype,64L

#define SN_setct_CapRevReqTBE           "setct-CapRevReqTBE"
#define NID_setct_CapRevReqTBE          583
#define OBJ_setct_CapRevReqTBE          OBJ_set_ctype,65L

#define SN_setct_CapRevReqTBEX          "setct-CapRevReqTBEX"
#define NID_setct_CapRevReqTBEX         584
#define OBJ_setct_CapRevReqTBEX         OBJ_set_ctype,66L

#define SN_setct_CapRevResTBE           "setct-CapRevResTBE"
#define NID_setct_CapRevResTBE          585
#define OBJ_setct_CapRevResTBE          OBJ_set_ctype,67L

#define SN_setct_CredReqTBE             "setct-CredReqTBE"
#define NID_setct_CredReqTBE            586
#define OBJ_setct_CredReqTBE            OBJ_set_ctype,68L

#define SN_setct_CredReqTBEX            "setct-CredReqTBEX"
#define NID_setct_CredReqTBEX           587
#define OBJ_setct_CredReqTBEX           OBJ_set_ctype,69L

#define SN_setct_CredResTBE             "setct-CredResTBE"
#define NID_setct_CredResTBE            588
#define OBJ_setct_CredResTBE            OBJ_set_ctype,70L

#define SN_setct_CredRevReqTBE          "setct-CredRevReqTBE"
#define NID_setct_CredRevReqTBE         589
#define OBJ_setct_CredRevReqTBE         OBJ_set_ctype,71L

#define SN_setct_CredRevReqTBEX         "setct-CredRevReqTBEX"
#define NID_setct_CredRevReqTBEX                590
#define OBJ_setct_CredRevReqTBEX                OBJ_set_ctype,72L

#define SN_setct_CredRevResTBE          "setct-CredRevResTBE"
#define NID_setct_CredRevResTBE         591
#define OBJ_setct_CredRevResTBE         OBJ_set_ctype,73L

#define SN_setct_BatchAdminReqTBE               "setct-BatchAdminReqTBE"
#define NID_setct_BatchAdminReqTBE              592
#define OBJ_setct_BatchAdminReqTBE              OBJ_set_ctype,74L

#define SN_setct_BatchAdminResTBE               "setct-BatchAdminResTBE"
#define NID_setct_BatchAdminResTBE              593
#define OBJ_setct_BatchAdminResTBE              OBJ_set_ctype,75L

#define SN_setct_RegFormReqTBE          "setct-RegFormReqTBE"
#define NID_setct_RegFormReqTBE         594
#define OBJ_setct_RegFormReqTBE         OBJ_set_ctype,76L

#define SN_setct_CertReqTBE             "setct-CertReqTBE"
#define NID_setct_CertReqTBE            595
#define OBJ_setct_CertReqTBE            OBJ_set_ctype,77L

#define SN_setct_CertReqTBEX            "setct-CertReqTBEX"
#define NID_setct_CertReqTBEX           596
#define OBJ_setct_CertReqTBEX           OBJ_set_ctype,78L

#define SN_setct_CertResTBE             "setct-CertResTBE"
#define NID_setct_CertResTBE            597
#define OBJ_setct_CertResTBE            OBJ_set_ctype,79L

#define SN_setct_CRLNotificationTBS             "setct-CRLNotificationTBS"
#define NID_setct_CRLNotificationTBS            598
#define OBJ_setct_CRLNotificationTBS            OBJ_set_ctype,80L

#define SN_setct_CRLNotificationResTBS          "setct-CRLNotificationResTBS"
#define NID_setct_CRLNotificationResTBS         599
#define OBJ_setct_CRLNotificationResTBS         OBJ_set_ctype,81L

#define SN_setct_BCIDistributionTBS             "setct-BCIDistributionTBS"
#define NID_setct_BCIDistributionTBS            600
#define OBJ_setct_BCIDistributionTBS            OBJ_set_ctype,82L

#define SN_setext_genCrypt              "setext-genCrypt"
#define LN_setext_genCrypt              "generic cryptogram"
#define NID_setext_genCrypt             601
#define OBJ_setext_genCrypt             OBJ_set_msgExt,1L

#define SN_setext_miAuth                "setext-miAuth"
#define LN_setext_miAuth                "merchant initiated auth"
#define NID_setext_miAuth               602
#define OBJ_setext_miAuth               OBJ_set_msgExt,3L

#define SN_setext_pinSecure             "setext-pinSecure"
#define NID_setext_pinSecure            603
#define OBJ_setext_pinSecure            OBJ_set_msgExt,4L

#define SN_setext_pinAny                "setext-pinAny"
#define NID_setext_pinAny               604
#define OBJ_setext_pinAny               OBJ_set_msgExt,5L

#define SN_setext_track2                "setext-track2"
#define NID_setext_track2               605
#define OBJ_setext_track2               OBJ_set_msgExt,7L

#define SN_setext_cv            "setext-cv"
#define LN_setext_cv            "additional verification"
#define NID_setext_cv           606
#define OBJ_setext_cv           OBJ_set_msgExt,8L

#define SN_set_policy_root              "set-policy-root"
#define NID_set_policy_root             607
#define OBJ_set_policy_root             OBJ_set_policy,0L

#define SN_setCext_hashedRoot           "setCext-hashedRoot"
#define NID_setCext_hashedRoot          608
#define OBJ_setCext_hashedRoot          OBJ_set_certExt,0L

#define SN_setCext_certType             "setCext-certType"
#define NID_setCext_certType            609
#define OBJ_setCext_certType            OBJ_set_certExt,1L

#define SN_setCext_merchData            "setCext-merchData"
#define NID_setCext_merchData           610
#define OBJ_setCext_merchData           OBJ_set_certExt,2L

#define SN_setCext_cCertRequired                "setCext-cCertRequired"
#define NID_setCext_cCertRequired               611
#define OBJ_setCext_cCertRequired               OBJ_set_certExt,3L

#define SN_setCext_tunneling            "setCext-tunneling"
#define NID_setCext_tunneling           612
#define OBJ_setCext_tunneling           OBJ_set_certExt,4L

#define SN_setCext_setExt               "setCext-setExt"
#define NID_setCext_setExt              613
#define OBJ_setCext_setExt              OBJ_set_certExt,5L

#define SN_setCext_setQualf             "setCext-setQualf"
#define NID_setCext_setQualf            614
#define OBJ_setCext_setQualf            OBJ_set_certExt,6L

#define SN_setCext_PGWYcapabilities             "setCext-PGWYcapabilities"
#define NID_setCext_PGWYcapabilities            615
#define OBJ_setCext_PGWYcapabilities            OBJ_set_certExt,7L

#define SN_setCext_TokenIdentifier              "setCext-TokenIdentifier"
#define NID_setCext_TokenIdentifier             616
#define OBJ_setCext_TokenIdentifier             OBJ_set_certExt,8L

#define SN_setCext_Track2Data           "setCext-Track2Data"
#define NID_setCext_Track2Data          617
#define OBJ_setCext_Track2Data          OBJ_set_certExt,9L

#define SN_setCext_TokenType            "setCext-TokenType"
#define NID_setCext_TokenType           618
#define OBJ_setCext_TokenType           OBJ_set_certExt,10L

#define SN_setCext_IssuerCapabilities           "setCext-IssuerCapabilities"
#define NID_setCext_IssuerCapabilities          619
#define OBJ_setCext_IssuerCapabilities          OBJ_set_certExt,11L

#define SN_setAttr_Cert         "setAttr-Cert"
#define NID_setAttr_Cert                620
#define OBJ_setAttr_Cert                OBJ_set_attr,0L

#define SN_setAttr_PGWYcap              "setAttr-PGWYcap"
#define LN_setAttr_PGWYcap              "payment gateway capabilities"
#define NID_setAttr_PGWYcap             621
#define OBJ_setAttr_PGWYcap             OBJ_set_attr,1L

#define SN_setAttr_TokenType            "setAttr-TokenType"
#define NID_setAttr_TokenType           622
#define OBJ_setAttr_TokenType           OBJ_set_attr,2L

#define SN_setAttr_IssCap               "setAttr-IssCap"
#define LN_setAttr_IssCap               "issuer capabilities"
#define NID_setAttr_IssCap              623
#define OBJ_setAttr_IssCap              OBJ_set_attr,3L

#define SN_set_rootKeyThumb             "set-rootKeyThumb"
#define NID_set_rootKeyThumb            624
#define OBJ_set_rootKeyThumb            OBJ_setAttr_Cert,0L

#define SN_set_addPolicy                "set-addPolicy"
#define NID_set_addPolicy               625
#define OBJ_set_addPolicy               OBJ_setAttr_Cert,1L

#define SN_setAttr_Token_EMV            "setAttr-Token-EMV"
#define NID_setAttr_Token_EMV           626
#define OBJ_setAttr_Token_EMV           OBJ_setAttr_TokenType,1L

#define SN_setAttr_Token_B0Prime                "setAttr-Token-B0Prime"
#define NID_setAttr_Token_B0Prime               627
#define OBJ_setAttr_Token_B0Prime               OBJ_setAttr_TokenType,2L

#define SN_setAttr_IssCap_CVM           "setAttr-IssCap-CVM"
#define NID_setAttr_IssCap_CVM          628
#define OBJ_setAttr_IssCap_CVM          OBJ_setAttr_IssCap,3L

#define SN_setAttr_IssCap_T2            "setAttr-IssCap-T2"
#define NID_setAttr_IssCap_T2           629
#define OBJ_setAttr_IssCap_T2           OBJ_setAttr_IssCap,4L

#define SN_setAttr_IssCap_Sig           "setAttr-IssCap-Sig"
#define NID_setAttr_IssCap_Sig          630
#define OBJ_setAttr_IssCap_Sig          OBJ_setAttr_IssCap,5L

#define SN_setAttr_GenCryptgrm          "setAttr-GenCryptgrm"
#define LN_setAttr_GenCryptgrm          "generate cryptogram"
#define NID_setAttr_GenCryptgrm         631
#define OBJ_setAttr_GenCryptgrm         OBJ_setAttr_IssCap_CVM,1L

#define SN_setAttr_T2Enc                "setAttr-T2Enc"
#define LN_setAttr_T2Enc                "encrypted track 2"
#define NID_setAttr_T2Enc               632
#define OBJ_setAttr_T2Enc               OBJ_setAttr_IssCap_T2,1L

#define SN_setAttr_T2cleartxt           "setAttr-T2cleartxt"
#define LN_setAttr_T2cleartxt           "cleartext track 2"
#define NID_setAttr_T2cleartxt          633
#define OBJ_setAttr_T2cleartxt          OBJ_setAttr_IssCap_T2,2L

#define SN_setAttr_TokICCsig            "setAttr-TokICCsig"
#define LN_setAttr_TokICCsig            "ICC or token signature"
#define NID_setAttr_TokICCsig           634
#define OBJ_setAttr_TokICCsig           OBJ_setAttr_IssCap_Sig,1L

#define SN_setAttr_SecDevSig            "setAttr-SecDevSig"
#define LN_setAttr_SecDevSig            "secure device signature"
#define NID_setAttr_SecDevSig           635
#define OBJ_setAttr_SecDevSig           OBJ_setAttr_IssCap_Sig,2L

#define SN_set_brand_IATA_ATA           "set-brand-IATA-ATA"
#define NID_set_brand_IATA_ATA          636
#define OBJ_set_brand_IATA_ATA          OBJ_set_brand,1L

#define SN_set_brand_Diners             "set-brand-Diners"
#define NID_set_brand_Diners            637
#define OBJ_set_brand_Diners            OBJ_set_brand,30L

#define SN_set_brand_AmericanExpress            "set-brand-AmericanExpress"
#define NID_set_brand_AmericanExpress           638
#define OBJ_set_brand_AmericanExpress           OBJ_set_brand,34L

#define SN_set_brand_JCB                "set-brand-JCB"
#define NID_set_brand_JCB               639
#define OBJ_set_brand_JCB               OBJ_set_brand,35L

#define SN_set_brand_Visa               "set-brand-Visa"
#define NID_set_brand_Visa              640
#define OBJ_set_brand_Visa              OBJ_set_brand,4L

#define SN_set_brand_MasterCard         "set-brand-MasterCard"
#define NID_set_brand_MasterCard                641
#define OBJ_set_brand_MasterCard                OBJ_set_brand,5L

#define SN_set_brand_Novus              "set-brand-Novus"
#define NID_set_brand_Novus             642
#define OBJ_set_brand_Novus             OBJ_set_brand,6011L

#define SN_des_cdmf             "DES-CDMF"
#define LN_des_cdmf             "des-cdmf"
#define NID_des_cdmf            643
#define OBJ_des_cdmf            OBJ_rsadsi,3L,10L

#define SN_rsaOAEPEncryptionSET         "rsaOAEPEncryptionSET"
#define NID_rsaOAEPEncryptionSET                644
#define OBJ_rsaOAEPEncryptionSET                OBJ_rsadsi,1L,1L,6L

#define SN_ipsec3               "Oakley-EC2N-3"
#define LN_ipsec3               "ipsec3"
#define NID_ipsec3              749

#define SN_ipsec4               "Oakley-EC2N-4"
#define LN_ipsec4               "ipsec4"
#define NID_ipsec4              750

#define SN_whirlpool            "whirlpool"
#define NID_whirlpool           804
#define OBJ_whirlpool           OBJ_iso,0L,10118L,3L,0L,55L

#define SN_cryptopro            "cryptopro"
#define NID_cryptopro           805
#define OBJ_cryptopro           OBJ_member_body,643L,2L,2L

#define SN_cryptocom            "cryptocom"
#define NID_cryptocom           806
#define OBJ_cryptocom           OBJ_member_body,643L,2L,9L

#define SN_id_tc26              "id-tc26"
#define NID_id_tc26             974
#define OBJ_id_tc26             OBJ_member_body,643L,7L,1L

#define SN_id_GostR3411_94_with_GostR3410_2001          "id-GostR3411-94-with-GostR3410-2001"
#define LN_id_GostR3411_94_with_GostR3410_2001          "GOST R 34.11-94 with GOST R 34.10-2001"
#define NID_id_GostR3411_94_with_GostR3410_2001         807
#define OBJ_id_GostR3411_94_with_GostR3410_2001         OBJ_cryptopro,3L

#define SN_id_GostR3411_94_with_GostR3410_94            "id-GostR3411-94-with-GostR3410-94"
#define LN_id_GostR3411_94_with_GostR3410_94            "GOST R 34.11-94 with GOST R 34.10-94"
#define NID_id_GostR3411_94_with_GostR3410_94           808
#define OBJ_id_GostR3411_94_with_GostR3410_94           OBJ_cryptopro,4L

#define SN_id_GostR3411_94              "md_gost94"
#define LN_id_GostR3411_94              "GOST R 34.11-94"
#define NID_id_GostR3411_94             809
#define OBJ_id_GostR3411_94             OBJ_cryptopro,9L

#define SN_id_HMACGostR3411_94          "id-HMACGostR3411-94"
#define LN_id_HMACGostR3411_94          "HMAC GOST 34.11-94"
#define NID_id_HMACGostR3411_94         810
#define OBJ_id_HMACGostR3411_94         OBJ_cryptopro,10L

#define SN_id_GostR3410_2001            "gost2001"
#define LN_id_GostR3410_2001            "GOST R 34.10-2001"
#define NID_id_GostR3410_2001           811
#define OBJ_id_GostR3410_2001           OBJ_cryptopro,19L

#define SN_id_GostR3410_94              "gost94"
#define LN_id_GostR3410_94              "GOST R 34.10-94"
#define NID_id_GostR3410_94             812
#define OBJ_id_GostR3410_94             OBJ_cryptopro,20L

#define SN_id_Gost28147_89              "gost89"
#define LN_id_Gost28147_89              "GOST 28147-89"
#define NID_id_Gost28147_89             813
#define OBJ_id_Gost28147_89             OBJ_cryptopro,21L

#define SN_gost89_cnt           "gost89-cnt"
#define NID_gost89_cnt          814

#define SN_gost89_cnt_12                "gost89-cnt-12"
#define NID_gost89_cnt_12               975

#define SN_gost89_cbc           "gost89-cbc"
#define NID_gost89_cbc          1009

#define SN_gost89_ecb           "gost89-ecb"
#define NID_gost89_ecb          1010

#define SN_gost89_ctr           "gost89-ctr"
#define NID_gost89_ctr          1011

#define SN_id_Gost28147_89_MAC          "gost-mac"
#define LN_id_Gost28147_89_MAC          "GOST 28147-89 MAC"
#define NID_id_Gost28147_89_MAC         815
#define OBJ_id_Gost28147_89_MAC         OBJ_cryptopro,22L

#define SN_gost_mac_12          "gost-mac-12"
#define NID_gost_mac_12         976

#define SN_id_GostR3411_94_prf          "prf-gostr3411-94"
#define LN_id_GostR3411_94_prf          "GOST R 34.11-94 PRF"
#define NID_id_GostR3411_94_prf         816
#define OBJ_id_GostR3411_94_prf         OBJ_cryptopro,23L

#define SN_id_GostR3410_2001DH          "id-GostR3410-2001DH"
#define LN_id_GostR3410_2001DH          "GOST R 34.10-2001 DH"
#define NID_id_GostR3410_2001DH         817
#define OBJ_id_GostR3410_2001DH         OBJ_cryptopro,98L

#define SN_id_GostR3410_94DH            "id-GostR3410-94DH"
#define LN_id_GostR3410_94DH            "GOST R 34.10-94 DH"
#define NID_id_GostR3410_94DH           818
#define OBJ_id_GostR3410_94DH           OBJ_cryptopro,99L

#define SN_id_Gost28147_89_CryptoPro_KeyMeshing         "id-Gost28147-89-CryptoPro-KeyMeshing"
#define NID_id_Gost28147_89_CryptoPro_KeyMeshing                819
#define OBJ_id_Gost28147_89_CryptoPro_KeyMeshing                OBJ_cryptopro,14L,1L

#define SN_id_Gost28147_89_None_KeyMeshing              "id-Gost28147-89-None-KeyMeshing"
#define NID_id_Gost28147_89_None_KeyMeshing             820
#define OBJ_id_Gost28147_89_None_KeyMeshing             OBJ_cryptopro,14L,0L

#define SN_id_GostR3411_94_TestParamSet         "id-GostR3411-94-TestParamSet"
#define NID_id_GostR3411_94_TestParamSet                821
#define OBJ_id_GostR3411_94_TestParamSet                OBJ_cryptopro,30L,0L

#define SN_id_GostR3411_94_CryptoProParamSet            "id-GostR3411-94-CryptoProParamSet"
#define NID_id_GostR3411_94_CryptoProParamSet           822
#define OBJ_id_GostR3411_94_CryptoProParamSet           OBJ_cryptopro,30L,1L

#define SN_id_Gost28147_89_TestParamSet         "id-Gost28147-89-TestParamSet"
#define NID_id_Gost28147_89_TestParamSet                823
#define OBJ_id_Gost28147_89_TestParamSet                OBJ_cryptopro,31L,0L

#define SN_id_Gost28147_89_CryptoPro_A_ParamSet         "id-Gost28147-89-CryptoPro-A-ParamSet"
#define NID_id_Gost28147_89_CryptoPro_A_ParamSet                824
#define OBJ_id_Gost28147_89_CryptoPro_A_ParamSet                OBJ_cryptopro,31L,1L

#define SN_id_Gost28147_89_CryptoPro_B_ParamSet         "id-Gost28147-89-CryptoPro-B-ParamSet"
#define NID_id_Gost28147_89_CryptoPro_B_ParamSet                825
#define OBJ_id_Gost28147_89_CryptoPro_B_ParamSet                OBJ_cryptopro,31L,2L

#define SN_id_Gost28147_89_CryptoPro_C_ParamSet         "id-Gost28147-89-CryptoPro-C-ParamSet"
#define NID_id_Gost28147_89_CryptoPro_C_ParamSet                826
#define OBJ_id_Gost28147_89_CryptoPro_C_ParamSet                OBJ_cryptopro,31L,3L

#define SN_id_Gost28147_89_CryptoPro_D_ParamSet         "id-Gost28147-89-CryptoPro-D-ParamSet"
#define NID_id_Gost28147_89_CryptoPro_D_ParamSet                827
#define OBJ_id_Gost28147_89_CryptoPro_D_ParamSet                OBJ_cryptopro,31L,4L

#define SN_id_Gost28147_89_CryptoPro_Oscar_1_1_ParamSet         "id-Gost28147-89-CryptoPro-Oscar-1-1-ParamSet"
#define NID_id_Gost28147_89_CryptoPro_Oscar_1_1_ParamSet                828
#define OBJ_id_Gost28147_89_CryptoPro_Oscar_1_1_ParamSet                OBJ_cryptopro,31L,5L

#define SN_id_Gost28147_89_CryptoPro_Oscar_1_0_ParamSet         "id-Gost28147-89-CryptoPro-Oscar-1-0-ParamSet"
#define NID_id_Gost28147_89_CryptoPro_Oscar_1_0_ParamSet                829
#define OBJ_id_Gost28147_89_CryptoPro_Oscar_1_0_ParamSet                OBJ_cryptopro,31L,6L

#define SN_id_Gost28147_89_CryptoPro_RIC_1_ParamSet             "id-Gost28147-89-CryptoPro-RIC-1-ParamSet"
#define NID_id_Gost28147_89_CryptoPro_RIC_1_ParamSet            830
#define OBJ_id_Gost28147_89_CryptoPro_RIC_1_ParamSet            OBJ_cryptopro,31L,7L

#define SN_id_GostR3410_94_TestParamSet         "id-GostR3410-94-TestParamSet"
#define NID_id_GostR3410_94_TestParamSet                831
#define OBJ_id_GostR3410_94_TestParamSet                OBJ_cryptopro,32L,0L

#define SN_id_GostR3410_94_CryptoPro_A_ParamSet         "id-GostR3410-94-CryptoPro-A-ParamSet"
#define NID_id_GostR3410_94_CryptoPro_A_ParamSet                832
#define OBJ_id_GostR3410_94_CryptoPro_A_ParamSet                OBJ_cryptopro,32L,2L

#define SN_id_GostR3410_94_CryptoPro_B_ParamSet         "id-GostR3410-94-CryptoPro-B-ParamSet"
#define NID_id_GostR3410_94_CryptoPro_B_ParamSet                833
#define OBJ_id_GostR3410_94_CryptoPro_B_ParamSet                OBJ_cryptopro,32L,3L

#define SN_id_GostR3410_94_CryptoPro_C_ParamSet         "id-GostR3410-94-CryptoPro-C-ParamSet"
#define NID_id_GostR3410_94_CryptoPro_C_ParamSet                834
#define OBJ_id_GostR3410_94_CryptoPro_C_ParamSet                OBJ_cryptopro,32L,4L

#define SN_id_GostR3410_94_CryptoPro_D_ParamSet         "id-GostR3410-94-CryptoPro-D-ParamSet"
#define NID_id_GostR3410_94_CryptoPro_D_ParamSet                835
#define OBJ_id_GostR3410_94_CryptoPro_D_ParamSet                OBJ_cryptopro,32L,5L

#define SN_id_GostR3410_94_CryptoPro_XchA_ParamSet              "id-GostR3410-94-CryptoPro-XchA-ParamSet"
#define NID_id_GostR3410_94_CryptoPro_XchA_ParamSet             836
#define OBJ_id_GostR3410_94_CryptoPro_XchA_ParamSet             OBJ_cryptopro,33L,1L

#define SN_id_GostR3410_94_CryptoPro_XchB_ParamSet              "id-GostR3410-94-CryptoPro-XchB-ParamSet"
#define NID_id_GostR3410_94_CryptoPro_XchB_ParamSet             837
#define OBJ_id_GostR3410_94_CryptoPro_XchB_ParamSet             OBJ_cryptopro,33L,2L

#define SN_id_GostR3410_94_CryptoPro_XchC_ParamSet              "id-GostR3410-94-CryptoPro-XchC-ParamSet"
#define NID_id_GostR3410_94_CryptoPro_XchC_ParamSet             838
#define OBJ_id_GostR3410_94_CryptoPro_XchC_ParamSet             OBJ_cryptopro,33L,3L

#define SN_id_GostR3410_2001_TestParamSet               "id-GostR3410-2001-TestParamSet"
#define NID_id_GostR3410_2001_TestParamSet              839
#define OBJ_id_GostR3410_2001_TestParamSet              OBJ_cryptopro,35L,0L

#define SN_id_GostR3410_2001_CryptoPro_A_ParamSet               "id-GostR3410-2001-CryptoPro-A-ParamSet"
#define NID_id_GostR3410_2001_CryptoPro_A_ParamSet              840
#define OBJ_id_GostR3410_2001_CryptoPro_A_ParamSet              OBJ_cryptopro,35L,1L

#define SN_id_GostR3410_2001_CryptoPro_B_ParamSet               "id-GostR3410-2001-CryptoPro-B-ParamSet"
#define NID_id_GostR3410_2001_CryptoPro_B_ParamSet              841
#define OBJ_id_GostR3410_2001_CryptoPro_B_ParamSet              OBJ_cryptopro,35L,2L

#define SN_id_GostR3410_2001_CryptoPro_C_ParamSet               "id-GostR3410-2001-CryptoPro-C-ParamSet"
#define NID_id_GostR3410_2001_CryptoPro_C_ParamSet              842
#define OBJ_id_GostR3410_2001_CryptoPro_C_ParamSet              OBJ_cryptopro,35L,3L

#define SN_id_GostR3410_2001_CryptoPro_XchA_ParamSet            "id-GostR3410-2001-CryptoPro-XchA-ParamSet"
#define NID_id_GostR3410_2001_CryptoPro_XchA_ParamSet           843
#define OBJ_id_GostR3410_2001_CryptoPro_XchA_ParamSet           OBJ_cryptopro,36L,0L

#define SN_id_GostR3410_2001_CryptoPro_XchB_ParamSet            "id-GostR3410-2001-CryptoPro-XchB-ParamSet"
#define NID_id_GostR3410_2001_CryptoPro_XchB_ParamSet           844
#define OBJ_id_GostR3410_2001_CryptoPro_XchB_ParamSet           OBJ_cryptopro,36L,1L

#define SN_id_GostR3410_94_a            "id-GostR3410-94-a"
#define NID_id_GostR3410_94_a           845
#define OBJ_id_GostR3410_94_a           OBJ_id_GostR3410_94,1L

#define SN_id_GostR3410_94_aBis         "id-GostR3410-94-aBis"
#define NID_id_GostR3410_94_aBis                846
#define OBJ_id_GostR3410_94_aBis                OBJ_id_GostR3410_94,2L

#define SN_id_GostR3410_94_b            "id-GostR3410-94-b"
#define NID_id_GostR3410_94_b           847
#define OBJ_id_GostR3410_94_b           OBJ_id_GostR3410_94,3L

#define SN_id_GostR3410_94_bBis         "id-GostR3410-94-bBis"
#define NID_id_GostR3410_94_bBis                848
#define OBJ_id_GostR3410_94_bBis                OBJ_id_GostR3410_94,4L

#define SN_id_Gost28147_89_cc           "id-Gost28147-89-cc"
#define LN_id_Gost28147_89_cc           "GOST 28147-89 Cryptocom ParamSet"
#define NID_id_Gost28147_89_cc          849
#define OBJ_id_Gost28147_89_cc          OBJ_cryptocom,1L,6L,1L

#define SN_id_GostR3410_94_cc           "gost94cc"
#define LN_id_GostR3410_94_cc           "GOST 34.10-94 Cryptocom"
#define NID_id_GostR3410_94_cc          850
#define OBJ_id_GostR3410_94_cc          OBJ_cryptocom,1L,5L,3L

#define SN_id_GostR3410_2001_cc         "gost2001cc"
#define LN_id_GostR3410_2001_cc         "GOST 34.10-2001 Cryptocom"
#define NID_id_GostR3410_2001_cc                851
#define OBJ_id_GostR3410_2001_cc                OBJ_cryptocom,1L,5L,4L

#define SN_id_GostR3411_94_with_GostR3410_94_cc         "id-GostR3411-94-with-GostR3410-94-cc"
#define LN_id_GostR3411_94_with_GostR3410_94_cc         "GOST R 34.11-94 with GOST R 34.10-94 Cryptocom"
#define NID_id_GostR3411_94_with_GostR3410_94_cc                852
#define OBJ_id_GostR3411_94_with_GostR3410_94_cc                OBJ_cryptocom,1L,3L,3L

#define SN_id_GostR3411_94_with_GostR3410_2001_cc               "id-GostR3411-94-with-GostR3410-2001-cc"
#define LN_id_GostR3411_94_with_GostR3410_2001_cc               "GOST R 34.11-94 with GOST R 34.10-2001 Cryptocom"
#define NID_id_GostR3411_94_with_GostR3410_2001_cc              853
#define OBJ_id_GostR3411_94_with_GostR3410_2001_cc              OBJ_cryptocom,1L,3L,4L

#define SN_id_GostR3410_2001_ParamSet_cc                "id-GostR3410-2001-ParamSet-cc"
#define LN_id_GostR3410_2001_ParamSet_cc                "GOST R 3410-2001 Parameter Set Cryptocom"
#define NID_id_GostR3410_2001_ParamSet_cc               854
#define OBJ_id_GostR3410_2001_ParamSet_cc               OBJ_cryptocom,1L,8L,1L

#define SN_id_tc26_algorithms           "id-tc26-algorithms"
#define NID_id_tc26_algorithms          977
#define OBJ_id_tc26_algorithms          OBJ_id_tc26,1L

#define SN_id_tc26_sign         "id-tc26-sign"
#define NID_id_tc26_sign                978
#define OBJ_id_tc26_sign                OBJ_id_tc26_algorithms,1L

#define SN_id_GostR3410_2012_256                "gost2012_256"
#define LN_id_GostR3410_2012_256                "GOST R 34.10-2012 with 256 bit modulus"
#define NID_id_GostR3410_2012_256               979
#define OBJ_id_GostR3410_2012_256               OBJ_id_tc26_sign,1L

#define SN_id_GostR3410_2012_512                "gost2012_512"
#define LN_id_GostR3410_2012_512                "GOST R 34.10-2012 with 512 bit modulus"
#define NID_id_GostR3410_2012_512               980
#define OBJ_id_GostR3410_2012_512               OBJ_id_tc26_sign,2L

#define SN_id_tc26_digest               "id-tc26-digest"
#define NID_id_tc26_digest              981
#define OBJ_id_tc26_digest              OBJ_id_tc26_algorithms,2L

#define SN_id_GostR3411_2012_256                "md_gost12_256"
#define LN_id_GostR3411_2012_256                "GOST R 34.11-2012 with 256 bit hash"
#define NID_id_GostR3411_2012_256               982
#define OBJ_id_GostR3411_2012_256               OBJ_id_tc26_digest,2L

#define SN_id_GostR3411_2012_512                "md_gost12_512"
#define LN_id_GostR3411_2012_512                "GOST R 34.11-2012 with 512 bit hash"
#define NID_id_GostR3411_2012_512               983
#define OBJ_id_GostR3411_2012_512               OBJ_id_tc26_digest,3L

#define SN_id_tc26_signwithdigest               "id-tc26-signwithdigest"
#define NID_id_tc26_signwithdigest              984
#define OBJ_id_tc26_signwithdigest              OBJ_id_tc26_algorithms,3L

#define SN_id_tc26_signwithdigest_gost3410_2012_256             "id-tc26-signwithdigest-gost3410-2012-256"
#define LN_id_tc26_signwithdigest_gost3410_2012_256             "GOST R 34.10-2012 with GOST R 34.11-2012 (256 bit)"
#define NID_id_tc26_signwithdigest_gost3410_2012_256            985
#define OBJ_id_tc26_signwithdigest_gost3410_2012_256            OBJ_id_tc26_signwithdigest,2L

#define SN_id_tc26_signwithdigest_gost3410_2012_512             "id-tc26-signwithdigest-gost3410-2012-512"
#define LN_id_tc26_signwithdigest_gost3410_2012_512             "GOST R 34.10-2012 with GOST R 34.11-2012 (512 bit)"
#define NID_id_tc26_signwithdigest_gost3410_2012_512            986
#define OBJ_id_tc26_signwithdigest_gost3410_2012_512            OBJ_id_tc26_signwithdigest,3L

#define SN_id_tc26_mac          "id-tc26-mac"
#define NID_id_tc26_mac         987
#define OBJ_id_tc26_mac         OBJ_id_tc26_algorithms,4L

#define SN_id_tc26_hmac_gost_3411_2012_256              "id-tc26-hmac-gost-3411-2012-256"
#define LN_id_tc26_hmac_gost_3411_2012_256              "HMAC GOST 34.11-2012 256 bit"
#define NID_id_tc26_hmac_gost_3411_2012_256             988
#define OBJ_id_tc26_hmac_gost_3411_2012_256             OBJ_id_tc26_mac,1L

#define SN_id_tc26_hmac_gost_3411_2012_512              "id-tc26-hmac-gost-3411-2012-512"
#define LN_id_tc26_hmac_gost_3411_2012_512              "HMAC GOST 34.11-2012 512 bit"
#define NID_id_tc26_hmac_gost_3411_2012_512             989
#define OBJ_id_tc26_hmac_gost_3411_2012_512             OBJ_id_tc26_mac,2L

#define SN_id_tc26_cipher               "id-tc26-cipher"
#define NID_id_tc26_cipher              990
#define OBJ_id_tc26_cipher              OBJ_id_tc26_algorithms,5L

#define SN_id_tc26_cipher_gostr3412_2015_magma          "id-tc26-cipher-gostr3412-2015-magma"
#define NID_id_tc26_cipher_gostr3412_2015_magma         1173
#define OBJ_id_tc26_cipher_gostr3412_2015_magma         OBJ_id_tc26_cipher,1L

#define SN_id_tc26_cipher_gostr3412_2015_magma_ctracpkm         "id-tc26-cipher-gostr3412-2015-magma-ctracpkm"
#define NID_id_tc26_cipher_gostr3412_2015_magma_ctracpkm                1174
#define OBJ_id_tc26_cipher_gostr3412_2015_magma_ctracpkm                OBJ_id_tc26_cipher_gostr3412_2015_magma,1L

#define SN_id_tc26_cipher_gostr3412_2015_magma_ctracpkm_omac            "id-tc26-cipher-gostr3412-2015-magma-ctracpkm-omac"
#define NID_id_tc26_cipher_gostr3412_2015_magma_ctracpkm_omac           1175
#define OBJ_id_tc26_cipher_gostr3412_2015_magma_ctracpkm_omac           OBJ_id_tc26_cipher_gostr3412_2015_magma,2L

#define SN_id_tc26_cipher_gostr3412_2015_kuznyechik             "id-tc26-cipher-gostr3412-2015-kuznyechik"
#define NID_id_tc26_cipher_gostr3412_2015_kuznyechik            1176
#define OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik            OBJ_id_tc26_cipher,2L

#define SN_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm            "id-tc26-cipher-gostr3412-2015-kuznyechik-ctracpkm"
#define NID_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm           1177
#define OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm           OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik,1L

#define SN_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm_omac               "id-tc26-cipher-gostr3412-2015-kuznyechik-ctracpkm-omac"
#define NID_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm_omac              1178
#define OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm_omac              OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik,2L

#define SN_id_tc26_agreement            "id-tc26-agreement"
#define NID_id_tc26_agreement           991
#define OBJ_id_tc26_agreement           OBJ_id_tc26_algorithms,6L

#define SN_id_tc26_agreement_gost_3410_2012_256         "id-tc26-agreement-gost-3410-2012-256"
#define NID_id_tc26_agreement_gost_3410_2012_256                992
#define OBJ_id_tc26_agreement_gost_3410_2012_256                OBJ_id_tc26_agreement,1L

#define SN_id_tc26_agreement_gost_3410_2012_512         "id-tc26-agreement-gost-3410-2012-512"
#define NID_id_tc26_agreement_gost_3410_2012_512                993
#define OBJ_id_tc26_agreement_gost_3410_2012_512                OBJ_id_tc26_agreement,2L

#define SN_id_tc26_wrap         "id-tc26-wrap"
#define NID_id_tc26_wrap                1179
#define OBJ_id_tc26_wrap                OBJ_id_tc26_algorithms,7L

#define SN_id_tc26_wrap_gostr3412_2015_magma            "id-tc26-wrap-gostr3412-2015-magma"
#define NID_id_tc26_wrap_gostr3412_2015_magma           1180
#define OBJ_id_tc26_wrap_gostr3412_2015_magma           OBJ_id_tc26_wrap,1L

#define SN_id_tc26_wrap_gostr3412_2015_magma_kexp15             "id-tc26-wrap-gostr3412-2015-magma-kexp15"
#define NID_id_tc26_wrap_gostr3412_2015_magma_kexp15            1181
#define OBJ_id_tc26_wrap_gostr3412_2015_magma_kexp15            OBJ_id_tc26_wrap_gostr3412_2015_magma,1L

#define SN_id_tc26_wrap_gostr3412_2015_kuznyechik               "id-tc26-wrap-gostr3412-2015-kuznyechik"
#define NID_id_tc26_wrap_gostr3412_2015_kuznyechik              1182
#define OBJ_id_tc26_wrap_gostr3412_2015_kuznyechik              OBJ_id_tc26_wrap,2L

#define SN_id_tc26_wrap_gostr3412_2015_kuznyechik_kexp15                "id-tc26-wrap-gostr3412-2015-kuznyechik-kexp15"
#define NID_id_tc26_wrap_gostr3412_2015_kuznyechik_kexp15               1183
#define OBJ_id_tc26_wrap_gostr3412_2015_kuznyechik_kexp15               OBJ_id_tc26_wrap_gostr3412_2015_kuznyechik,1L

#define SN_id_tc26_constants            "id-tc26-constants"
#define NID_id_tc26_constants           994
#define OBJ_id_tc26_constants           OBJ_id_tc26,2L

#define SN_id_tc26_sign_constants               "id-tc26-sign-constants"
#define NID_id_tc26_sign_constants              995
#define OBJ_id_tc26_sign_constants              OBJ_id_tc26_constants,1L

#define SN_id_tc26_gost_3410_2012_256_constants         "id-tc26-gost-3410-2012-256-constants"
#define NID_id_tc26_gost_3410_2012_256_constants                1147
#define OBJ_id_tc26_gost_3410_2012_256_constants                OBJ_id_tc26_sign_constants,1L

#define SN_id_tc26_gost_3410_2012_256_paramSetA         "id-tc26-gost-3410-2012-256-paramSetA"
#define LN_id_tc26_gost_3410_2012_256_paramSetA         "GOST R 34.10-2012 (256 bit) ParamSet A"
#define NID_id_tc26_gost_3410_2012_256_paramSetA                1148
#define OBJ_id_tc26_gost_3410_2012_256_paramSetA                OBJ_id_tc26_gost_3410_2012_256_constants,1L

#define SN_id_tc26_gost_3410_2012_256_paramSetB         "id-tc26-gost-3410-2012-256-paramSetB"
#define LN_id_tc26_gost_3410_2012_256_paramSetB         "GOST R 34.10-2012 (256 bit) ParamSet B"
#define NID_id_tc26_gost_3410_2012_256_paramSetB                1184
#define OBJ_id_tc26_gost_3410_2012_256_paramSetB                OBJ_id_tc26_gost_3410_2012_256_constants,2L

#define SN_id_tc26_gost_3410_2012_256_paramSetC         "id-tc26-gost-3410-2012-256-paramSetC"
#define LN_id_tc26_gost_3410_2012_256_paramSetC         "GOST R 34.10-2012 (256 bit) ParamSet C"
#define NID_id_tc26_gost_3410_2012_256_paramSetC                1185
#define OBJ_id_tc26_gost_3410_2012_256_paramSetC                OBJ_id_tc26_gost_3410_2012_256_constants,3L

#define SN_id_tc26_gost_3410_2012_256_paramSetD         "id-tc26-gost-3410-2012-256-paramSetD"
#define LN_id_tc26_gost_3410_2012_256_paramSetD         "GOST R 34.10-2012 (256 bit) ParamSet D"
#define NID_id_tc26_gost_3410_2012_256_paramSetD                1186
#define OBJ_id_tc26_gost_3410_2012_256_paramSetD                OBJ_id_tc26_gost_3410_2012_256_constants,4L

#define SN_id_tc26_gost_3410_2012_512_constants         "id-tc26-gost-3410-2012-512-constants"
#define NID_id_tc26_gost_3410_2012_512_constants                996
#define OBJ_id_tc26_gost_3410_2012_512_constants                OBJ_id_tc26_sign_constants,2L

#define SN_id_tc26_gost_3410_2012_512_paramSetTest              "id-tc26-gost-3410-2012-512-paramSetTest"
#define LN_id_tc26_gost_3410_2012_512_paramSetTest              "GOST R 34.10-2012 (512 bit) testing parameter set"
#define NID_id_tc26_gost_3410_2012_512_paramSetTest             997
#define OBJ_id_tc26_gost_3410_2012_512_paramSetTest             OBJ_id_tc26_gost_3410_2012_512_constants,0L

#define SN_id_tc26_gost_3410_2012_512_paramSetA         "id-tc26-gost-3410-2012-512-paramSetA"
#define LN_id_tc26_gost_3410_2012_512_paramSetA         "GOST R 34.10-2012 (512 bit) ParamSet A"
#define NID_id_tc26_gost_3410_2012_512_paramSetA                998
#define OBJ_id_tc26_gost_3410_2012_512_paramSetA                OBJ_id_tc26_gost_3410_2012_512_constants,1L

#define SN_id_tc26_gost_3410_2012_512_paramSetB         "id-tc26-gost-3410-2012-512-paramSetB"
#define LN_id_tc26_gost_3410_2012_512_paramSetB         "GOST R 34.10-2012 (512 bit) ParamSet B"
#define NID_id_tc26_gost_3410_2012_512_paramSetB                999
#define OBJ_id_tc26_gost_3410_2012_512_paramSetB                OBJ_id_tc26_gost_3410_2012_512_constants,2L

#define SN_id_tc26_gost_3410_2012_512_paramSetC         "id-tc26-gost-3410-2012-512-paramSetC"
#define LN_id_tc26_gost_3410_2012_512_paramSetC         "GOST R 34.10-2012 (512 bit) ParamSet C"
#define NID_id_tc26_gost_3410_2012_512_paramSetC                1149
#define OBJ_id_tc26_gost_3410_2012_512_paramSetC                OBJ_id_tc26_gost_3410_2012_512_constants,3L

#define SN_id_tc26_digest_constants             "id-tc26-digest-constants"
#define NID_id_tc26_digest_constants            1000
#define OBJ_id_tc26_digest_constants            OBJ_id_tc26_constants,2L

#define SN_id_tc26_cipher_constants             "id-tc26-cipher-constants"
#define NID_id_tc26_cipher_constants            1001
#define OBJ_id_tc26_cipher_constants            OBJ_id_tc26_constants,5L

#define SN_id_tc26_gost_28147_constants         "id-tc26-gost-28147-constants"
#define NID_id_tc26_gost_28147_constants                1002
#define OBJ_id_tc26_gost_28147_constants                OBJ_id_tc26_cipher_constants,1L

#define SN_id_tc26_gost_28147_param_Z           "id-tc26-gost-28147-param-Z"
#define LN_id_tc26_gost_28147_param_Z           "GOST 28147-89 TC26 parameter set"
#define NID_id_tc26_gost_28147_param_Z          1003
#define OBJ_id_tc26_gost_28147_param_Z          OBJ_id_tc26_gost_28147_constants,1L

#define SN_INN          "INN"
#define LN_INN          "INN"
#define NID_INN         1004
#define OBJ_INN         OBJ_member_body,643L,3L,131L,1L,1L

#define SN_OGRN         "OGRN"
#define LN_OGRN         "OGRN"
#define NID_OGRN                1005
#define OBJ_OGRN                OBJ_member_body,643L,100L,1L

#define SN_SNILS                "SNILS"
#define LN_SNILS                "SNILS"
#define NID_SNILS               1006
#define OBJ_SNILS               OBJ_member_body,643L,100L,3L

#define SN_subjectSignTool              "subjectSignTool"
#define LN_subjectSignTool              "Signing Tool of Subject"
#define NID_subjectSignTool             1007
#define OBJ_subjectSignTool             OBJ_member_body,643L,100L,111L

#define SN_issuerSignTool               "issuerSignTool"
#define LN_issuerSignTool               "Signing Tool of Issuer"
#define NID_issuerSignTool              1008
#define OBJ_issuerSignTool              OBJ_member_body,643L,100L,112L

#define SN_grasshopper_ecb              "grasshopper-ecb"
#define NID_grasshopper_ecb             1012

#define SN_grasshopper_ctr              "grasshopper-ctr"
#define NID_grasshopper_ctr             1013

#define SN_grasshopper_ofb              "grasshopper-ofb"
#define NID_grasshopper_ofb             1014

#define SN_grasshopper_cbc              "grasshopper-cbc"
#define NID_grasshopper_cbc             1015

#define SN_grasshopper_cfb              "grasshopper-cfb"
#define NID_grasshopper_cfb             1016

#define SN_grasshopper_mac              "grasshopper-mac"
#define NID_grasshopper_mac             1017

#define SN_magma_ecb            "magma-ecb"
#define NID_magma_ecb           1187

#define SN_magma_ctr            "magma-ctr"
#define NID_magma_ctr           1188

#define SN_magma_ofb            "magma-ofb"
#define NID_magma_ofb           1189

#define SN_magma_cbc            "magma-cbc"
#define NID_magma_cbc           1190

#define SN_magma_cfb            "magma-cfb"
#define NID_magma_cfb           1191

#define SN_magma_mac            "magma-mac"
#define NID_magma_mac           1192

#define SN_camellia_128_cbc             "CAMELLIA-128-CBC"
#define LN_camellia_128_cbc             "camellia-128-cbc"
#define NID_camellia_128_cbc            751
#define OBJ_camellia_128_cbc            1L,2L,392L,200011L,61L,1L,1L,1L,2L

#define SN_camellia_192_cbc             "CAMELLIA-192-CBC"
#define LN_camellia_192_cbc             "camellia-192-cbc"
#define NID_camellia_192_cbc            752
#define OBJ_camellia_192_cbc            1L,2L,392L,200011L,61L,1L,1L,1L,3L

#define SN_camellia_256_cbc             "CAMELLIA-256-CBC"
#define LN_camellia_256_cbc             "camellia-256-cbc"
#define NID_camellia_256_cbc            753
#define OBJ_camellia_256_cbc            1L,2L,392L,200011L,61L,1L,1L,1L,4L

#define SN_id_camellia128_wrap          "id-camellia128-wrap"
#define NID_id_camellia128_wrap         907
#define OBJ_id_camellia128_wrap         1L,2L,392L,200011L,61L,1L,1L,3L,2L

#define SN_id_camellia192_wrap          "id-camellia192-wrap"
#define NID_id_camellia192_wrap         908
#define OBJ_id_camellia192_wrap         1L,2L,392L,200011L,61L,1L,1L,3L,3L

#define SN_id_camellia256_wrap          "id-camellia256-wrap"
#define NID_id_camellia256_wrap         909
#define OBJ_id_camellia256_wrap         1L,2L,392L,200011L,61L,1L,1L,3L,4L

#define OBJ_ntt_ds              0L,3L,4401L,5L

#define OBJ_camellia            OBJ_ntt_ds,3L,1L,9L

#define SN_camellia_128_ecb             "CAMELLIA-128-ECB"
#define LN_camellia_128_ecb             "camellia-128-ecb"
#define NID_camellia_128_ecb            754
#define OBJ_camellia_128_ecb            OBJ_camellia,1L

#define SN_camellia_128_ofb128          "CAMELLIA-128-OFB"
#define LN_camellia_128_ofb128          "camellia-128-ofb"
#define NID_camellia_128_ofb128         766
#define OBJ_camellia_128_ofb128         OBJ_camellia,3L

#define SN_camellia_128_cfb128          "CAMELLIA-128-CFB"
#define LN_camellia_128_cfb128          "camellia-128-cfb"
#define NID_camellia_128_cfb128         757
#define OBJ_camellia_128_cfb128         OBJ_camellia,4L

#define SN_camellia_128_gcm             "CAMELLIA-128-GCM"
#define LN_camellia_128_gcm             "camellia-128-gcm"
#define NID_camellia_128_gcm            961
#define OBJ_camellia_128_gcm            OBJ_camellia,6L

#define SN_camellia_128_ccm             "CAMELLIA-128-CCM"
#define LN_camellia_128_ccm             "camellia-128-ccm"
#define NID_camellia_128_ccm            962
#define OBJ_camellia_128_ccm            OBJ_camellia,7L

#define SN_camellia_128_ctr             "CAMELLIA-128-CTR"
#define LN_camellia_128_ctr             "camellia-128-ctr"
#define NID_camellia_128_ctr            963
#define OBJ_camellia_128_ctr            OBJ_camellia,9L

#define SN_camellia_128_cmac            "CAMELLIA-128-CMAC"
#define LN_camellia_128_cmac            "camellia-128-cmac"
#define NID_camellia_128_cmac           964
#define OBJ_camellia_128_cmac           OBJ_camellia,10L

#define SN_camellia_192_ecb             "CAMELLIA-192-ECB"
#define LN_camellia_192_ecb             "camellia-192-ecb"
#define NID_camellia_192_ecb            755
#define OBJ_camellia_192_ecb            OBJ_camellia,21L

#define SN_camellia_192_ofb128          "CAMELLIA-192-OFB"
#define LN_camellia_192_ofb128          "camellia-192-ofb"
#define NID_camellia_192_ofb128         767
#define OBJ_camellia_192_ofb128         OBJ_camellia,23L

#define SN_camellia_192_cfb128          "CAMELLIA-192-CFB"
#define LN_camellia_192_cfb128          "camellia-192-cfb"
#define NID_camellia_192_cfb128         758
#define OBJ_camellia_192_cfb128         OBJ_camellia,24L

#define SN_camellia_192_gcm             "CAMELLIA-192-GCM"
#define LN_camellia_192_gcm             "camellia-192-gcm"
#define NID_camellia_192_gcm            965
#define OBJ_camellia_192_gcm            OBJ_camellia,26L

#define SN_camellia_192_ccm             "CAMELLIA-192-CCM"
#define LN_camellia_192_ccm             "camellia-192-ccm"
#define NID_camellia_192_ccm            966
#define OBJ_camellia_192_ccm            OBJ_camellia,27L

#define SN_camellia_192_ctr             "CAMELLIA-192-CTR"
#define LN_camellia_192_ctr             "camellia-192-ctr"
#define NID_camellia_192_ctr            967
#define OBJ_camellia_192_ctr            OBJ_camellia,29L

#define SN_camellia_192_cmac            "CAMELLIA-192-CMAC"
#define LN_camellia_192_cmac            "camellia-192-cmac"
#define NID_camellia_192_cmac           968
#define OBJ_camellia_192_cmac           OBJ_camellia,30L

#define SN_camellia_256_ecb             "CAMELLIA-256-ECB"
#define LN_camellia_256_ecb             "camellia-256-ecb"
#define NID_camellia_256_ecb            756
#define OBJ_camellia_256_ecb            OBJ_camellia,41L

#define SN_camellia_256_ofb128          "CAMELLIA-256-OFB"
#define LN_camellia_256_ofb128          "camellia-256-ofb"
#define NID_camellia_256_ofb128         768
#define OBJ_camellia_256_ofb128         OBJ_camellia,43L

#define SN_camellia_256_cfb128          "CAMELLIA-256-CFB"
#define LN_camellia_256_cfb128          "camellia-256-cfb"
#define NID_camellia_256_cfb128         759
#define OBJ_camellia_256_cfb128         OBJ_camellia,44L

#define SN_camellia_256_gcm             "CAMELLIA-256-GCM"
#define LN_camellia_256_gcm             "camellia-256-gcm"
#define NID_camellia_256_gcm            969
#define OBJ_camellia_256_gcm            OBJ_camellia,46L

#define SN_camellia_256_ccm             "CAMELLIA-256-CCM"
#define LN_camellia_256_ccm             "camellia-256-ccm"
#define NID_camellia_256_ccm            970
#define OBJ_camellia_256_ccm            OBJ_camellia,47L

#define SN_camellia_256_ctr             "CAMELLIA-256-CTR"
#define LN_camellia_256_ctr             "camellia-256-ctr"
#define NID_camellia_256_ctr            971
#define OBJ_camellia_256_ctr            OBJ_camellia,49L

#define SN_camellia_256_cmac            "CAMELLIA-256-CMAC"
#define LN_camellia_256_cmac            "camellia-256-cmac"
#define NID_camellia_256_cmac           972
#define OBJ_camellia_256_cmac           OBJ_camellia,50L

#define SN_camellia_128_cfb1            "CAMELLIA-128-CFB1"
#define LN_camellia_128_cfb1            "camellia-128-cfb1"
#define NID_camellia_128_cfb1           760

#define SN_camellia_192_cfb1            "CAMELLIA-192-CFB1"
#define LN_camellia_192_cfb1            "camellia-192-cfb1"
#define NID_camellia_192_cfb1           761

#define SN_camellia_256_cfb1            "CAMELLIA-256-CFB1"
#define LN_camellia_256_cfb1            "camellia-256-cfb1"
#define NID_camellia_256_cfb1           762

#define SN_camellia_128_cfb8            "CAMELLIA-128-CFB8"
#define LN_camellia_128_cfb8            "camellia-128-cfb8"
#define NID_camellia_128_cfb8           763

#define SN_camellia_192_cfb8            "CAMELLIA-192-CFB8"
#define LN_camellia_192_cfb8            "camellia-192-cfb8"
#define NID_camellia_192_cfb8           764

#define SN_camellia_256_cfb8            "CAMELLIA-256-CFB8"
#define LN_camellia_256_cfb8            "camellia-256-cfb8"
#define NID_camellia_256_cfb8           765

#define OBJ_aria                1L,2L,410L,200046L,1L,1L

#define SN_aria_128_ecb         "ARIA-128-ECB"
#define LN_aria_128_ecb         "aria-128-ecb"
#define NID_aria_128_ecb                1065
#define OBJ_aria_128_ecb                OBJ_aria,1L

#define SN_aria_128_cbc         "ARIA-128-CBC"
#define LN_aria_128_cbc         "aria-128-cbc"
#define NID_aria_128_cbc                1066
#define OBJ_aria_128_cbc                OBJ_aria,2L

#define SN_aria_128_cfb128              "ARIA-128-CFB"
#define LN_aria_128_cfb128              "aria-128-cfb"
#define NID_aria_128_cfb128             1067
#define OBJ_aria_128_cfb128             OBJ_aria,3L

#define SN_aria_128_ofb128              "ARIA-128-OFB"
#define LN_aria_128_ofb128              "aria-128-ofb"
#define NID_aria_128_ofb128             1068
#define OBJ_aria_128_ofb128             OBJ_aria,4L

#define SN_aria_128_ctr         "ARIA-128-CTR"
#define LN_aria_128_ctr         "aria-128-ctr"
#define NID_aria_128_ctr                1069
#define OBJ_aria_128_ctr                OBJ_aria,5L

#define SN_aria_192_ecb         "ARIA-192-ECB"
#define LN_aria_192_ecb         "aria-192-ecb"
#define NID_aria_192_ecb                1070
#define OBJ_aria_192_ecb                OBJ_aria,6L

#define SN_aria_192_cbc         "ARIA-192-CBC"
#define LN_aria_192_cbc         "aria-192-cbc"
#define NID_aria_192_cbc                1071
#define OBJ_aria_192_cbc                OBJ_aria,7L

#define SN_aria_192_cfb128              "ARIA-192-CFB"
#define LN_aria_192_cfb128              "aria-192-cfb"
#define NID_aria_192_cfb128             1072
#define OBJ_aria_192_cfb128             OBJ_aria,8L

#define SN_aria_192_ofb128              "ARIA-192-OFB"
#define LN_aria_192_ofb128              "aria-192-ofb"
#define NID_aria_192_ofb128             1073
#define OBJ_aria_192_ofb128             OBJ_aria,9L

#define SN_aria_192_ctr         "ARIA-192-CTR"
#define LN_aria_192_ctr         "aria-192-ctr"
#define NID_aria_192_ctr                1074
#define OBJ_aria_192_ctr                OBJ_aria,10L

#define SN_aria_256_ecb         "ARIA-256-ECB"
#define LN_aria_256_ecb         "aria-256-ecb"
#define NID_aria_256_ecb                1075
#define OBJ_aria_256_ecb                OBJ_aria,11L

#define SN_aria_256_cbc         "ARIA-256-CBC"
#define LN_aria_256_cbc         "aria-256-cbc"
#define NID_aria_256_cbc                1076
#define OBJ_aria_256_cbc                OBJ_aria,12L

#define SN_aria_256_cfb128              "ARIA-256-CFB"
#define LN_aria_256_cfb128              "aria-256-cfb"
#define NID_aria_256_cfb128             1077
#define OBJ_aria_256_cfb128             OBJ_aria,13L

#define SN_aria_256_ofb128              "ARIA-256-OFB"
#define LN_aria_256_ofb128              "aria-256-ofb"
#define NID_aria_256_ofb128             1078
#define OBJ_aria_256_ofb128             OBJ_aria,14L

#define SN_aria_256_ctr         "ARIA-256-CTR"
#define LN_aria_256_ctr         "aria-256-ctr"
#define NID_aria_256_ctr                1079
#define OBJ_aria_256_ctr                OBJ_aria,15L

#define SN_aria_128_cfb1                "ARIA-128-CFB1"
#define LN_aria_128_cfb1                "aria-128-cfb1"
#define NID_aria_128_cfb1               1080

#define SN_aria_192_cfb1                "ARIA-192-CFB1"
#define LN_aria_192_cfb1                "aria-192-cfb1"
#define NID_aria_192_cfb1               1081

#define SN_aria_256_cfb1                "ARIA-256-CFB1"
#define LN_aria_256_cfb1                "aria-256-cfb1"
#define NID_aria_256_cfb1               1082

#define SN_aria_128_cfb8                "ARIA-128-CFB8"
#define LN_aria_128_cfb8                "aria-128-cfb8"
#define NID_aria_128_cfb8               1083

#define SN_aria_192_cfb8                "ARIA-192-CFB8"
#define LN_aria_192_cfb8                "aria-192-cfb8"
#define NID_aria_192_cfb8               1084

#define SN_aria_256_cfb8                "ARIA-256-CFB8"
#define LN_aria_256_cfb8                "aria-256-cfb8"
#define NID_aria_256_cfb8               1085

#define SN_aria_128_ccm         "ARIA-128-CCM"
#define LN_aria_128_ccm         "aria-128-ccm"
#define NID_aria_128_ccm                1120
#define OBJ_aria_128_ccm                OBJ_aria,37L

#define SN_aria_192_ccm         "ARIA-192-CCM"
#define LN_aria_192_ccm         "aria-192-ccm"
#define NID_aria_192_ccm                1121
#define OBJ_aria_192_ccm                OBJ_aria,38L

#define SN_aria_256_ccm         "ARIA-256-CCM"
#define LN_aria_256_ccm         "aria-256-ccm"
#define NID_aria_256_ccm                1122
#define OBJ_aria_256_ccm                OBJ_aria,39L

#define SN_aria_128_gcm         "ARIA-128-GCM"
#define LN_aria_128_gcm         "aria-128-gcm"
#define NID_aria_128_gcm                1123
#define OBJ_aria_128_gcm                OBJ_aria,34L

#define SN_aria_192_gcm         "ARIA-192-GCM"
#define LN_aria_192_gcm         "aria-192-gcm"
#define NID_aria_192_gcm                1124
#define OBJ_aria_192_gcm                OBJ_aria,35L

#define SN_aria_256_gcm         "ARIA-256-GCM"
#define LN_aria_256_gcm         "aria-256-gcm"
#define NID_aria_256_gcm                1125
#define OBJ_aria_256_gcm                OBJ_aria,36L

#define SN_kisa         "KISA"
#define LN_kisa         "kisa"
#define NID_kisa                773
#define OBJ_kisa                OBJ_member_body,410L,200004L

#define SN_seed_ecb             "SEED-ECB"
#define LN_seed_ecb             "seed-ecb"
#define NID_seed_ecb            776
#define OBJ_seed_ecb            OBJ_kisa,1L,3L

#define SN_seed_cbc             "SEED-CBC"
#define LN_seed_cbc             "seed-cbc"
#define NID_seed_cbc            777
#define OBJ_seed_cbc            OBJ_kisa,1L,4L

#define SN_seed_cfb128          "SEED-CFB"
#define LN_seed_cfb128          "seed-cfb"
#define NID_seed_cfb128         779
#define OBJ_seed_cfb128         OBJ_kisa,1L,5L

#define SN_seed_ofb128          "SEED-OFB"
#define LN_seed_ofb128          "seed-ofb"
#define NID_seed_ofb128         778
#define OBJ_seed_ofb128         OBJ_kisa,1L,6L

#define SN_sm4_ecb              "SM4-ECB"
#define LN_sm4_ecb              "sm4-ecb"
#define NID_sm4_ecb             1133
#define OBJ_sm4_ecb             OBJ_sm_scheme,104L,1L

#define SN_sm4_cbc              "SM4-CBC"
#define LN_sm4_cbc              "sm4-cbc"
#define NID_sm4_cbc             1134
#define OBJ_sm4_cbc             OBJ_sm_scheme,104L,2L

#define SN_sm4_ofb128           "SM4-OFB"
#define LN_sm4_ofb128           "sm4-ofb"
#define NID_sm4_ofb128          1135
#define OBJ_sm4_ofb128          OBJ_sm_scheme,104L,3L

#define SN_sm4_cfb128           "SM4-CFB"
#define LN_sm4_cfb128           "sm4-cfb"
#define NID_sm4_cfb128          1137
#define OBJ_sm4_cfb128          OBJ_sm_scheme,104L,4L

#define SN_sm4_cfb1             "SM4-CFB1"
#define LN_sm4_cfb1             "sm4-cfb1"
#define NID_sm4_cfb1            1136
#define OBJ_sm4_cfb1            OBJ_sm_scheme,104L,5L

#define SN_sm4_cfb8             "SM4-CFB8"
#define LN_sm4_cfb8             "sm4-cfb8"
#define NID_sm4_cfb8            1138
#define OBJ_sm4_cfb8            OBJ_sm_scheme,104L,6L

#define SN_sm4_ctr              "SM4-CTR"
#define LN_sm4_ctr              "sm4-ctr"
#define NID_sm4_ctr             1139
#define OBJ_sm4_ctr             OBJ_sm_scheme,104L,7L

#define SN_hmac         "HMAC"
#define LN_hmac         "hmac"
#define NID_hmac                855

#define SN_cmac         "CMAC"
#define LN_cmac         "cmac"
#define NID_cmac                894

#define SN_rc4_hmac_md5         "RC4-HMAC-MD5"
#define LN_rc4_hmac_md5         "rc4-hmac-md5"
#define NID_rc4_hmac_md5                915

#define SN_aes_128_cbc_hmac_sha1                "AES-128-CBC-HMAC-SHA1"
#define LN_aes_128_cbc_hmac_sha1                "aes-128-cbc-hmac-sha1"
#define NID_aes_128_cbc_hmac_sha1               916

#define SN_aes_192_cbc_hmac_sha1                "AES-192-CBC-HMAC-SHA1"
#define LN_aes_192_cbc_hmac_sha1                "aes-192-cbc-hmac-sha1"
#define NID_aes_192_cbc_hmac_sha1               917

#define SN_aes_256_cbc_hmac_sha1                "AES-256-CBC-HMAC-SHA1"
#define LN_aes_256_cbc_hmac_sha1                "aes-256-cbc-hmac-sha1"
#define NID_aes_256_cbc_hmac_sha1               918

#define SN_aes_128_cbc_hmac_sha256              "AES-128-CBC-HMAC-SHA256"
#define LN_aes_128_cbc_hmac_sha256              "aes-128-cbc-hmac-sha256"
#define NID_aes_128_cbc_hmac_sha256             948

#define SN_aes_192_cbc_hmac_sha256              "AES-192-CBC-HMAC-SHA256"
#define LN_aes_192_cbc_hmac_sha256              "aes-192-cbc-hmac-sha256"
#define NID_aes_192_cbc_hmac_sha256             949

#define SN_aes_256_cbc_hmac_sha256              "AES-256-CBC-HMAC-SHA256"
#define LN_aes_256_cbc_hmac_sha256              "aes-256-cbc-hmac-sha256"
#define NID_aes_256_cbc_hmac_sha256             950

#define SN_chacha20_poly1305            "ChaCha20-Poly1305"
#define LN_chacha20_poly1305            "chacha20-poly1305"
#define NID_chacha20_poly1305           1018

#define SN_chacha20             "ChaCha20"
#define LN_chacha20             "chacha20"
#define NID_chacha20            1019

#define SN_dhpublicnumber               "dhpublicnumber"
#define LN_dhpublicnumber               "X9.42 DH"
#define NID_dhpublicnumber              920
#define OBJ_dhpublicnumber              OBJ_ISO_US,10046L,2L,1L

#define SN_brainpoolP160r1              "brainpoolP160r1"
#define NID_brainpoolP160r1             921
#define OBJ_brainpoolP160r1             1L,3L,36L,3L,3L,2L,8L,1L,1L,1L

#define SN_brainpoolP160t1              "brainpoolP160t1"
#define NID_brainpoolP160t1             922
#define OBJ_brainpoolP160t1             1L,3L,36L,3L,3L,2L,8L,1L,1L,2L

#define SN_brainpoolP192r1              "brainpoolP192r1"
#define NID_brainpoolP192r1             923
#define OBJ_brainpoolP192r1             1L,3L,36L,3L,3L,2L,8L,1L,1L,3L

#define SN_brainpoolP192t1              "brainpoolP192t1"
#define NID_brainpoolP192t1             924
#define OBJ_brainpoolP192t1             1L,3L,36L,3L,3L,2L,8L,1L,1L,4L

#define SN_brainpoolP224r1              "brainpoolP224r1"
#define NID_brainpoolP224r1             925
#define OBJ_brainpoolP224r1             1L,3L,36L,3L,3L,2L,8L,1L,1L,5L

#define SN_brainpoolP224t1              "brainpoolP224t1"
#define NID_brainpoolP224t1             926
#define OBJ_brainpoolP224t1             1L,3L,36L,3L,3L,2L,8L,1L,1L,6L

#define SN_brainpoolP256r1              "brainpoolP256r1"
#define NID_brainpoolP256r1             927
#define OBJ_brainpoolP256r1             1L,3L,36L,3L,3L,2L,8L,1L,1L,7L

#define SN_brainpoolP256t1              "brainpoolP256t1"
#define NID_brainpoolP256t1             928
#define OBJ_brainpoolP256t1             1L,3L,36L,3L,3L,2L,8L,1L,1L,8L

#define SN_brainpoolP320r1              "brainpoolP320r1"
#define NID_brainpoolP320r1             929
#define OBJ_brainpoolP320r1             1L,3L,36L,3L,3L,2L,8L,1L,1L,9L

#define SN_brainpoolP320t1              "brainpoolP320t1"
#define NID_brainpoolP320t1             930
#define OBJ_brainpoolP320t1             1L,3L,36L,3L,3L,2L,8L,1L,1L,10L

#define SN_brainpoolP384r1              "brainpoolP384r1"
#define NID_brainpoolP384r1             931
#define OBJ_brainpoolP384r1             1L,3L,36L,3L,3L,2L,8L,1L,1L,11L

#define SN_brainpoolP384t1              "brainpoolP384t1"
#define NID_brainpoolP384t1             932
#define OBJ_brainpoolP384t1             1L,3L,36L,3L,3L,2L,8L,1L,1L,12L

#define SN_brainpoolP512r1              "brainpoolP512r1"
#define NID_brainpoolP512r1             933
#define OBJ_brainpoolP512r1             1L,3L,36L,3L,3L,2L,8L,1L,1L,13L

#define SN_brainpoolP512t1              "brainpoolP512t1"
#define NID_brainpoolP512t1             934
#define OBJ_brainpoolP512t1             1L,3L,36L,3L,3L,2L,8L,1L,1L,14L

#define OBJ_x9_63_scheme                1L,3L,133L,16L,840L,63L,0L

#define OBJ_secg_scheme         OBJ_certicom_arc,1L

#define SN_dhSinglePass_stdDH_sha1kdf_scheme            "dhSinglePass-stdDH-sha1kdf-scheme"
#define NID_dhSinglePass_stdDH_sha1kdf_scheme           936
#define OBJ_dhSinglePass_stdDH_sha1kdf_scheme           OBJ_x9_63_scheme,2L

#define SN_dhSinglePass_stdDH_sha224kdf_scheme          "dhSinglePass-stdDH-sha224kdf-scheme"
#define NID_dhSinglePass_stdDH_sha224kdf_scheme         937
#define OBJ_dhSinglePass_stdDH_sha224kdf_scheme         OBJ_secg_scheme,11L,0L

#define SN_dhSinglePass_stdDH_sha256kdf_scheme          "dhSinglePass-stdDH-sha256kdf-scheme"
#define NID_dhSinglePass_stdDH_sha256kdf_scheme         938
#define OBJ_dhSinglePass_stdDH_sha256kdf_scheme         OBJ_secg_scheme,11L,1L

#define SN_dhSinglePass_stdDH_sha384kdf_scheme          "dhSinglePass-stdDH-sha384kdf-scheme"
#define NID_dhSinglePass_stdDH_sha384kdf_scheme         939
#define OBJ_dhSinglePass_stdDH_sha384kdf_scheme         OBJ_secg_scheme,11L,2L

#define SN_dhSinglePass_stdDH_sha512kdf_scheme          "dhSinglePass-stdDH-sha512kdf-scheme"
#define NID_dhSinglePass_stdDH_sha512kdf_scheme         940
#define OBJ_dhSinglePass_stdDH_sha512kdf_scheme         OBJ_secg_scheme,11L,3L

#define SN_dhSinglePass_cofactorDH_sha1kdf_scheme               "dhSinglePass-cofactorDH-sha1kdf-scheme"
#define NID_dhSinglePass_cofactorDH_sha1kdf_scheme              941
#define OBJ_dhSinglePass_cofactorDH_sha1kdf_scheme              OBJ_x9_63_scheme,3L

#define SN_dhSinglePass_cofactorDH_sha224kdf_scheme             "dhSinglePass-cofactorDH-sha224kdf-scheme"
#define NID_dhSinglePass_cofactorDH_sha224kdf_scheme            942
#define OBJ_dhSinglePass_cofactorDH_sha224kdf_scheme            OBJ_secg_scheme,14L,0L

#define SN_dhSinglePass_cofactorDH_sha256kdf_scheme             "dhSinglePass-cofactorDH-sha256kdf-scheme"
#define NID_dhSinglePass_cofactorDH_sha256kdf_scheme            943
#define OBJ_dhSinglePass_cofactorDH_sha256kdf_scheme            OBJ_secg_scheme,14L,1L

#define SN_dhSinglePass_cofactorDH_sha384kdf_scheme             "dhSinglePass-cofactorDH-sha384kdf-scheme"
#define NID_dhSinglePass_cofactorDH_sha384kdf_scheme            944
#define OBJ_dhSinglePass_cofactorDH_sha384kdf_scheme            OBJ_secg_scheme,14L,2L

#define SN_dhSinglePass_cofactorDH_sha512kdf_scheme             "dhSinglePass-cofactorDH-sha512kdf-scheme"
#define NID_dhSinglePass_cofactorDH_sha512kdf_scheme            945
#define OBJ_dhSinglePass_cofactorDH_sha512kdf_scheme            OBJ_secg_scheme,14L,3L

#define SN_dh_std_kdf           "dh-std-kdf"
#define NID_dh_std_kdf          946

#define SN_dh_cofactor_kdf              "dh-cofactor-kdf"
#define NID_dh_cofactor_kdf             947

#define SN_ct_precert_scts              "ct_precert_scts"
#define LN_ct_precert_scts              "CT Precertificate SCTs"
#define NID_ct_precert_scts             951
#define OBJ_ct_precert_scts             1L,3L,6L,1L,4L,1L,11129L,2L,4L,2L

#define SN_ct_precert_poison            "ct_precert_poison"
#define LN_ct_precert_poison            "CT Precertificate Poison"
#define NID_ct_precert_poison           952
#define OBJ_ct_precert_poison           1L,3L,6L,1L,4L,1L,11129L,2L,4L,3L

#define SN_ct_precert_signer            "ct_precert_signer"
#define LN_ct_precert_signer            "CT Precertificate Signer"
#define NID_ct_precert_signer           953
#define OBJ_ct_precert_signer           1L,3L,6L,1L,4L,1L,11129L,2L,4L,4L

#define SN_ct_cert_scts         "ct_cert_scts"
#define LN_ct_cert_scts         "CT Certificate SCTs"
#define NID_ct_cert_scts                954
#define OBJ_ct_cert_scts                1L,3L,6L,1L,4L,1L,11129L,2L,4L,5L

#define SN_jurisdictionLocalityName             "jurisdictionL"
#define LN_jurisdictionLocalityName             "jurisdictionLocalityName"
#define NID_jurisdictionLocalityName            955
#define OBJ_jurisdictionLocalityName            1L,3L,6L,1L,4L,1L,311L,60L,2L,1L,1L

#define SN_jurisdictionStateOrProvinceName              "jurisdictionST"
#define LN_jurisdictionStateOrProvinceName              "jurisdictionStateOrProvinceName"
#define NID_jurisdictionStateOrProvinceName             956
#define OBJ_jurisdictionStateOrProvinceName             1L,3L,6L,1L,4L,1L,311L,60L,2L,1L,2L

#define SN_jurisdictionCountryName              "jurisdictionC"
#define LN_jurisdictionCountryName              "jurisdictionCountryName"
#define NID_jurisdictionCountryName             957
#define OBJ_jurisdictionCountryName             1L,3L,6L,1L,4L,1L,311L,60L,2L,1L,3L

#define SN_id_scrypt            "id-scrypt"
#define LN_id_scrypt            "scrypt"
#define NID_id_scrypt           973
#define OBJ_id_scrypt           1L,3L,6L,1L,4L,1L,11591L,4L,11L

#define SN_tls1_prf             "TLS1-PRF"
#define LN_tls1_prf             "tls1-prf"
#define NID_tls1_prf            1021

#define SN_hkdf         "HKDF"
#define LN_hkdf         "hkdf"
#define NID_hkdf                1036

#define SN_id_pkinit            "id-pkinit"
#define NID_id_pkinit           1031
#define OBJ_id_pkinit           1L,3L,6L,1L,5L,2L,3L

#define SN_pkInitClientAuth             "pkInitClientAuth"
#define LN_pkInitClientAuth             "PKINIT Client Auth"
#define NID_pkInitClientAuth            1032
#define OBJ_pkInitClientAuth            OBJ_id_pkinit,4L

#define SN_pkInitKDC            "pkInitKDC"
#define LN_pkInitKDC            "Signing KDC Response"
#define NID_pkInitKDC           1033
#define OBJ_pkInitKDC           OBJ_id_pkinit,5L

#define SN_X25519               "X25519"
#define NID_X25519              1034
#define OBJ_X25519              1L,3L,101L,110L

#define SN_X448         "X448"
#define NID_X448                1035
#define OBJ_X448                1L,3L,101L,111L

#define SN_ED25519              "ED25519"
#define NID_ED25519             1087
#define OBJ_ED25519             1L,3L,101L,112L

#define SN_ED448                "ED448"
#define NID_ED448               1088
#define OBJ_ED448               1L,3L,101L,113L

#define SN_kx_rsa               "KxRSA"
#define LN_kx_rsa               "kx-rsa"
#define NID_kx_rsa              1037

#define SN_kx_ecdhe             "KxECDHE"
#define LN_kx_ecdhe             "kx-ecdhe"
#define NID_kx_ecdhe            1038

#define SN_kx_dhe               "KxDHE"
#define LN_kx_dhe               "kx-dhe"
#define NID_kx_dhe              1039

#define SN_kx_ecdhe_psk         "KxECDHE-PSK"
#define LN_kx_ecdhe_psk         "kx-ecdhe-psk"
#define NID_kx_ecdhe_psk                1040

#define SN_kx_dhe_psk           "KxDHE-PSK"
#define LN_kx_dhe_psk           "kx-dhe-psk"
#define NID_kx_dhe_psk          1041

#define SN_kx_rsa_psk           "KxRSA_PSK"
#define LN_kx_rsa_psk           "kx-rsa-psk"
#define NID_kx_rsa_psk          1042

#define SN_kx_psk               "KxPSK"
#define LN_kx_psk               "kx-psk"
#define NID_kx_psk              1043

#define SN_kx_srp               "KxSRP"
#define LN_kx_srp               "kx-srp"
#define NID_kx_srp              1044

#define SN_kx_gost              "KxGOST"
#define LN_kx_gost              "kx-gost"
#define NID_kx_gost             1045

#define SN_kx_any               "KxANY"
#define LN_kx_any               "kx-any"
#define NID_kx_any              1063

#define SN_auth_rsa             "AuthRSA"
#define LN_auth_rsa             "auth-rsa"
#define NID_auth_rsa            1046

#define SN_auth_ecdsa           "AuthECDSA"
#define LN_auth_ecdsa           "auth-ecdsa"
#define NID_auth_ecdsa          1047

#define SN_auth_psk             "AuthPSK"
#define LN_auth_psk             "auth-psk"
#define NID_auth_psk            1048

#define SN_auth_dss             "AuthDSS"
#define LN_auth_dss             "auth-dss"
#define NID_auth_dss            1049

#define SN_auth_gost01          "AuthGOST01"
#define LN_auth_gost01          "auth-gost01"
#define NID_auth_gost01         1050

#define SN_auth_gost12          "AuthGOST12"
#define LN_auth_gost12          "auth-gost12"
#define NID_auth_gost12         1051

#define SN_auth_srp             "AuthSRP"
#define LN_auth_srp             "auth-srp"
#define NID_auth_srp            1052

#define SN_auth_null            "AuthNULL"
#define LN_auth_null            "auth-null"
#define NID_auth_null           1053

#define SN_auth_any             "AuthANY"
#define LN_auth_any             "auth-any"
#define NID_auth_any            1064

#define SN_poly1305             "Poly1305"
#define LN_poly1305             "poly1305"
#define NID_poly1305            1061

#define SN_siphash              "SipHash"
#define LN_siphash              "siphash"
#define NID_siphash             1062

#define SN_ffdhe2048            "ffdhe2048"
#define NID_ffdhe2048           1126

#define SN_ffdhe3072            "ffdhe3072"
#define NID_ffdhe3072           1127

#define SN_ffdhe4096            "ffdhe4096"
#define NID_ffdhe4096           1128

#define SN_ffdhe6144            "ffdhe6144"
#define NID_ffdhe6144           1129

#define SN_ffdhe8192            "ffdhe8192"
#define NID_ffdhe8192           1130

#define SN_ISO_UA               "ISO-UA"
#define NID_ISO_UA              1150
#define OBJ_ISO_UA              OBJ_member_body,804L

#define SN_ua_pki               "ua-pki"
#define NID_ua_pki              1151
#define OBJ_ua_pki              OBJ_ISO_UA,2L,1L,1L,1L

#define SN_dstu28147            "dstu28147"
#define LN_dstu28147            "DSTU Gost 28147-2009"
#define NID_dstu28147           1152
#define OBJ_dstu28147           OBJ_ua_pki,1L,1L,1L

#define SN_dstu28147_ofb                "dstu28147-ofb"
#define LN_dstu28147_ofb                "DSTU Gost 28147-2009 OFB mode"
#define NID_dstu28147_ofb               1153
#define OBJ_dstu28147_ofb               OBJ_dstu28147,2L

#define SN_dstu28147_cfb                "dstu28147-cfb"
#define LN_dstu28147_cfb                "DSTU Gost 28147-2009 CFB mode"
#define NID_dstu28147_cfb               1154
#define OBJ_dstu28147_cfb               OBJ_dstu28147,3L

#define SN_dstu28147_wrap               "dstu28147-wrap"
#define LN_dstu28147_wrap               "DSTU Gost 28147-2009 key wrap"
#define NID_dstu28147_wrap              1155
#define OBJ_dstu28147_wrap              OBJ_dstu28147,5L

#define SN_hmacWithDstu34311            "hmacWithDstu34311"
#define LN_hmacWithDstu34311            "HMAC DSTU Gost 34311-95"
#define NID_hmacWithDstu34311           1156
#define OBJ_hmacWithDstu34311           OBJ_ua_pki,1L,1L,2L

#define SN_dstu34311            "dstu34311"
#define LN_dstu34311            "DSTU Gost 34311-95"
#define NID_dstu34311           1157
#define OBJ_dstu34311           OBJ_ua_pki,1L,2L,1L

#define SN_dstu4145le           "dstu4145le"
#define LN_dstu4145le           "DSTU 4145-2002 little endian"
#define NID_dstu4145le          1158
#define OBJ_dstu4145le          OBJ_ua_pki,1L,3L,1L,1L

#define SN_dstu4145be           "dstu4145be"
#define LN_dstu4145be           "DSTU 4145-2002 big endian"
#define NID_dstu4145be          1159
#define OBJ_dstu4145be          OBJ_dstu4145le,1L,1L

#define SN_uacurve0             "uacurve0"
#define LN_uacurve0             "DSTU curve 0"
#define NID_uacurve0            1160
#define OBJ_uacurve0            OBJ_dstu4145le,2L,0L

#define SN_uacurve1             "uacurve1"
#define LN_uacurve1             "DSTU curve 1"
#define NID_uacurve1            1161
#define OBJ_uacurve1            OBJ_dstu4145le,2L,1L

#define SN_uacurve2             "uacurve2"
#define LN_uacurve2             "DSTU curve 2"
#define NID_uacurve2            1162
#define OBJ_uacurve2            OBJ_dstu4145le,2L,2L

#define SN_uacurve3             "uacurve3"
#define LN_uacurve3             "DSTU curve 3"
#define NID_uacurve3            1163
#define OBJ_uacurve3            OBJ_dstu4145le,2L,3L

#define SN_uacurve4             "uacurve4"
#define LN_uacurve4             "DSTU curve 4"
#define NID_uacurve4            1164
#define OBJ_uacurve4            OBJ_dstu4145le,2L,4L

#define SN_uacurve5             "uacurve5"
#define LN_uacurve5             "DSTU curve 5"
#define NID_uacurve5            1165
#define OBJ_uacurve5            OBJ_dstu4145le,2L,5L

#define SN_uacurve6             "uacurve6"
#define LN_uacurve6             "DSTU curve 6"
#define NID_uacurve6            1166
#define OBJ_uacurve6            OBJ_dstu4145le,2L,6L

#define SN_uacurve7             "uacurve7"
#define LN_uacurve7             "DSTU curve 7"
#define NID_uacurve7            1167
#define OBJ_uacurve7            OBJ_dstu4145le,2L,7L

#define SN_uacurve8             "uacurve8"
#define LN_uacurve8             "DSTU curve 8"
#define NID_uacurve8            1168
#define OBJ_uacurve8            OBJ_dstu4145le,2L,8L

#define SN_uacurve9             "uacurve9"
#define LN_uacurve9             "DSTU curve 9"
#define NID_uacurve9            1169
#define OBJ_uacurve9            OBJ_dstu4145le,2L,9L

/* Serialized OID's */
static const unsigned char so[7762] = {
    0x2A,0x86,0x48,0x86,0xF7,0x0D,                 /* [    0] OBJ_rsadsi */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,            /* [    6] OBJ_pkcs */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x02,       /* [   13] OBJ_md2 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x05,       /* [   21] OBJ_md5 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x03,0x04,       /* [   29] OBJ_rc4 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x01,  /* [   37] OBJ_rsaEncryption */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x02,  /* [   46] OBJ_md2WithRSAEncryption */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x04,  /* [   55] OBJ_md5WithRSAEncryption */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,0x01,  /* [   64] OBJ_pbeWithMD2AndDES_CBC */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,0x03,  /* [   73] OBJ_pbeWithMD5AndDES_CBC */
    0x55,                                          /* [   82] OBJ_X500 */
    0x55,0x04,                                     /* [   83] OBJ_X509 */
    0x55,0x04,0x03,                                /* [   85] OBJ_commonName */
    0x55,0x04,0x06,                                /* [   88] OBJ_countryName */
    0x55,0x04,0x07,                                /* [   91] OBJ_localityName */
    0x55,0x04,0x08,                                /* [   94] OBJ_stateOrProvinceName */
    0x55,0x04,0x0A,                                /* [   97] OBJ_organizationName */
    0x55,0x04,0x0B,                                /* [  100] OBJ_organizationalUnitName */
    0x55,0x08,0x01,0x01,                           /* [  103] OBJ_rsa */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x07,       /* [  107] OBJ_pkcs7 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x07,0x01,  /* [  115] OBJ_pkcs7_data */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x07,0x02,  /* [  124] OBJ_pkcs7_signed */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x07,0x03,  /* [  133] OBJ_pkcs7_enveloped */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x07,0x04,  /* [  142] OBJ_pkcs7_signedAndEnveloped */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x07,0x05,  /* [  151] OBJ_pkcs7_digest */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x07,0x06,  /* [  160] OBJ_pkcs7_encrypted */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x03,       /* [  169] OBJ_pkcs3 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x03,0x01,  /* [  177] OBJ_dhKeyAgreement */
    0x2B,0x0E,0x03,0x02,0x06,                      /* [  186] OBJ_des_ecb */
    0x2B,0x0E,0x03,0x02,0x09,                      /* [  191] OBJ_des_cfb64 */
    0x2B,0x0E,0x03,0x02,0x07,                      /* [  196] OBJ_des_cbc */
    0x2B,0x0E,0x03,0x02,0x11,                      /* [  201] OBJ_des_ede_ecb */
    0x2B,0x06,0x01,0x04,0x01,0x81,0x3C,0x07,0x01,0x01,0x02,  /* [  206] OBJ_idea_cbc */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x03,0x02,       /* [  217] OBJ_rc2_cbc */
    0x2B,0x0E,0x03,0x02,0x12,                      /* [  225] OBJ_sha */
    0x2B,0x0E,0x03,0x02,0x0F,                      /* [  230] OBJ_shaWithRSAEncryption */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x03,0x07,       /* [  235] OBJ_des_ede3_cbc */
    0x2B,0x0E,0x03,0x02,0x08,                      /* [  243] OBJ_des_ofb64 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,       /* [  248] OBJ_pkcs9 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x01,  /* [  256] OBJ_pkcs9_emailAddress */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x02,  /* [  265] OBJ_pkcs9_unstructuredName */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x03,  /* [  274] OBJ_pkcs9_contentType */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x04,  /* [  283] OBJ_pkcs9_messageDigest */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x05,  /* [  292] OBJ_pkcs9_signingTime */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x06,  /* [  301] OBJ_pkcs9_countersignature */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x07,  /* [  310] OBJ_pkcs9_challengePassword */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x08,  /* [  319] OBJ_pkcs9_unstructuredAddress */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x09,  /* [  328] OBJ_pkcs9_extCertAttributes */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,            /* [  337] OBJ_netscape */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x01,       /* [  344] OBJ_netscape_cert_extension */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x02,       /* [  352] OBJ_netscape_data_type */
    0x2B,0x0E,0x03,0x02,0x1A,                      /* [  360] OBJ_sha1 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x05,  /* [  365] OBJ_sha1WithRSAEncryption */
    0x2B,0x0E,0x03,0x02,0x0D,                      /* [  374] OBJ_dsaWithSHA */
    0x2B,0x0E,0x03,0x02,0x0C,                      /* [  379] OBJ_dsa_2 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,0x0B,  /* [  384] OBJ_pbeWithSHA1AndRC2_CBC */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,0x0C,  /* [  393] OBJ_id_pbkdf2 */
    0x2B,0x0E,0x03,0x02,0x1B,                      /* [  402] OBJ_dsaWithSHA1_2 */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x01,0x01,  /* [  407] OBJ_netscape_cert_type */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x01,0x02,  /* [  416] OBJ_netscape_base_url */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x01,0x03,  /* [  425] OBJ_netscape_revocation_url */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x01,0x04,  /* [  434] OBJ_netscape_ca_revocation_url */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x01,0x07,  /* [  443] OBJ_netscape_renewal_url */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x01,0x08,  /* [  452] OBJ_netscape_ca_policy_url */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x01,0x0C,  /* [  461] OBJ_netscape_ssl_server_name */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x01,0x0D,  /* [  470] OBJ_netscape_comment */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x02,0x05,  /* [  479] OBJ_netscape_cert_sequence */
    0x55,0x1D,                                     /* [  488] OBJ_id_ce */
    0x55,0x1D,0x0E,                                /* [  490] OBJ_subject_key_identifier */
    0x55,0x1D,0x0F,                                /* [  493] OBJ_key_usage */
    0x55,0x1D,0x10,                                /* [  496] OBJ_private_key_usage_period */
    0x55,0x1D,0x11,                                /* [  499] OBJ_subject_alt_name */
    0x55,0x1D,0x12,                                /* [  502] OBJ_issuer_alt_name */
    0x55,0x1D,0x13,                                /* [  505] OBJ_basic_constraints */
    0x55,0x1D,0x14,                                /* [  508] OBJ_crl_number */
    0x55,0x1D,0x20,                                /* [  511] OBJ_certificate_policies */
    0x55,0x1D,0x23,                                /* [  514] OBJ_authority_key_identifier */
    0x2B,0x06,0x01,0x04,0x01,0x97,0x55,0x01,0x02,  /* [  517] OBJ_bf_cbc */
    0x55,0x08,0x03,0x65,                           /* [  526] OBJ_mdc2 */
    0x55,0x08,0x03,0x64,                           /* [  530] OBJ_mdc2WithRSA */
    0x55,0x04,0x2A,                                /* [  534] OBJ_givenName */
    0x55,0x04,0x04,                                /* [  537] OBJ_surname */
    0x55,0x04,0x2B,                                /* [  540] OBJ_initials */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x2C,  /* [  543] OBJ_uniqueIdentifier */
    0x55,0x1D,0x1F,                                /* [  553] OBJ_crl_distribution_points */
    0x2B,0x0E,0x03,0x02,0x03,                      /* [  556] OBJ_md5WithRSA */
    0x55,0x04,0x05,                                /* [  561] OBJ_serialNumber */
    0x55,0x04,0x0C,                                /* [  564] OBJ_title */
    0x55,0x04,0x0D,                                /* [  567] OBJ_description */
    0x2A,0x86,0x48,0x86,0xF6,0x7D,0x07,0x42,0x0A,  /* [  570] OBJ_cast5_cbc */
    0x2A,0x86,0x48,0x86,0xF6,0x7D,0x07,0x42,0x0C,  /* [  579] OBJ_pbeWithMD5AndCast5_CBC */
    0x2A,0x86,0x48,0xCE,0x38,0x04,0x03,            /* [  588] OBJ_dsaWithSHA1 */
    0x2B,0x0E,0x03,0x02,0x1D,                      /* [  595] OBJ_sha1WithRSA */
    0x2A,0x86,0x48,0xCE,0x38,0x04,0x01,            /* [  600] OBJ_dsa */
    0x2B,0x24,0x03,0x02,0x01,                      /* [  607] OBJ_ripemd160 */
    0x2B,0x24,0x03,0x03,0x01,0x02,                 /* [  612] OBJ_ripemd160WithRSA */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x03,0x08,       /* [  618] OBJ_rc5_cbc */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,0x08,  /* [  626] OBJ_zlib_compression */
    0x55,0x1D,0x25,                                /* [  637] OBJ_ext_key_usage */
    0x2B,0x06,0x01,0x05,0x05,0x07,                 /* [  640] OBJ_id_pkix */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,            /* [  646] OBJ_id_kp */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x01,       /* [  653] OBJ_server_auth */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x02,       /* [  661] OBJ_client_auth */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x03,       /* [  669] OBJ_code_sign */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x04,       /* [  677] OBJ_email_protect */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x08,       /* [  685] OBJ_time_stamp */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x02,0x01,0x15,  /* [  693] OBJ_ms_code_ind */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x02,0x01,0x16,  /* [  703] OBJ_ms_code_com */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x0A,0x03,0x01,  /* [  713] OBJ_ms_ctl_sign */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x0A,0x03,0x03,  /* [  723] OBJ_ms_sgc */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x0A,0x03,0x04,  /* [  733] OBJ_ms_efs */
    0x60,0x86,0x48,0x01,0x86,0xF8,0x42,0x04,0x01,  /* [  743] OBJ_ns_sgc */
    0x55,0x1D,0x1B,                                /* [  752] OBJ_delta_crl */
    0x55,0x1D,0x15,                                /* [  755] OBJ_crl_reason */
    0x55,0x1D,0x18,                                /* [  758] OBJ_invalidity_date */
    0x2B,0x65,0x01,0x04,0x01,                      /* [  761] OBJ_sxnet */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x01,0x01,  /* [  766] OBJ_pbe_WithSHA1And128BitRC4 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x01,0x02,  /* [  776] OBJ_pbe_WithSHA1And40BitRC4 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x01,0x03,  /* [  786] OBJ_pbe_WithSHA1And3_Key_TripleDES_CBC */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x01,0x04,  /* [  796] OBJ_pbe_WithSHA1And2_Key_TripleDES_CBC */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x01,0x05,  /* [  806] OBJ_pbe_WithSHA1And128BitRC2_CBC */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x01,0x06,  /* [  816] OBJ_pbe_WithSHA1And40BitRC2_CBC */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x0A,0x01,0x01,  /* [  826] OBJ_keyBag */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x0A,0x01,0x02,  /* [  837] OBJ_pkcs8ShroudedKeyBag */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x0A,0x01,0x03,  /* [  848] OBJ_certBag */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x0A,0x01,0x04,  /* [  859] OBJ_crlBag */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x0A,0x01,0x05,  /* [  870] OBJ_secretBag */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x0C,0x0A,0x01,0x06,  /* [  881] OBJ_safeContentsBag */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x14,  /* [  892] OBJ_friendlyName */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x15,  /* [  901] OBJ_localKeyID */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x16,0x01,  /* [  910] OBJ_x509Certificate */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x16,0x02,  /* [  920] OBJ_sdsiCertificate */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x17,0x01,  /* [  930] OBJ_x509Crl */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,0x0D,  /* [  940] OBJ_pbes2 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,0x0E,  /* [  949] OBJ_pbmac1 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x07,       /* [  958] OBJ_hmacWithSHA1 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x02,0x01,       /* [  966] OBJ_id_qt_cps */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x02,0x02,       /* [  974] OBJ_id_qt_unotice */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x0F,  /* [  982] OBJ_SMIMECapabilities */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,0x04,  /* [  991] OBJ_pbeWithMD2AndRC2_CBC */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,0x06,  /* [ 1000] OBJ_pbeWithMD5AndRC2_CBC */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,0x0A,  /* [ 1009] OBJ_pbeWithSHA1AndDES_CBC */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x02,0x01,0x0E,  /* [ 1018] OBJ_ms_ext_req */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x0E,  /* [ 1028] OBJ_ext_req */
    0x55,0x04,0x29,                                /* [ 1037] OBJ_name */
    0x55,0x04,0x2E,                                /* [ 1040] OBJ_dnQualifier */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,            /* [ 1043] OBJ_id_pe */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,            /* [ 1050] OBJ_id_ad */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x01,       /* [ 1057] OBJ_info_access */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,       /* [ 1065] OBJ_ad_OCSP */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x02,       /* [ 1073] OBJ_ad_ca_issuers */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x09,       /* [ 1081] OBJ_OCSP_sign */
    0x2A,                                          /* [ 1089] OBJ_member_body */
    0x2A,0x86,0x48,                                /* [ 1090] OBJ_ISO_US */
    0x2A,0x86,0x48,0xCE,0x38,                      /* [ 1093] OBJ_X9_57 */
    0x2A,0x86,0x48,0xCE,0x38,0x04,                 /* [ 1098] OBJ_X9cm */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,       /* [ 1104] OBJ_pkcs1 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x05,       /* [ 1112] OBJ_pkcs5 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,  /* [ 1120] OBJ_SMIME */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x00,  /* [ 1129] OBJ_id_smime_mod */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,  /* [ 1139] OBJ_id_smime_ct */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,  /* [ 1149] OBJ_id_smime_aa */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,  /* [ 1159] OBJ_id_smime_alg */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x04,  /* [ 1169] OBJ_id_smime_cd */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x05,  /* [ 1179] OBJ_id_smime_spq */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x06,  /* [ 1189] OBJ_id_smime_cti */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x00,0x01,  /* [ 1199] OBJ_id_smime_mod_cms */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x00,0x02,  /* [ 1210] OBJ_id_smime_mod_ess */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x00,0x03,  /* [ 1221] OBJ_id_smime_mod_oid */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x00,0x04,  /* [ 1232] OBJ_id_smime_mod_msg_v3 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x00,0x05,  /* [ 1243] OBJ_id_smime_mod_ets_eSignature_88 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x00,0x06,  /* [ 1254] OBJ_id_smime_mod_ets_eSignature_97 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x00,0x07,  /* [ 1265] OBJ_id_smime_mod_ets_eSigPolicy_88 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x00,0x08,  /* [ 1276] OBJ_id_smime_mod_ets_eSigPolicy_97 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x01,  /* [ 1287] OBJ_id_smime_ct_receipt */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x02,  /* [ 1298] OBJ_id_smime_ct_authData */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x03,  /* [ 1309] OBJ_id_smime_ct_publishCert */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x04,  /* [ 1320] OBJ_id_smime_ct_TSTInfo */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x05,  /* [ 1331] OBJ_id_smime_ct_TDTInfo */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x06,  /* [ 1342] OBJ_id_smime_ct_contentInfo */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x07,  /* [ 1353] OBJ_id_smime_ct_DVCSRequestData */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x08,  /* [ 1364] OBJ_id_smime_ct_DVCSResponseData */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x01,  /* [ 1375] OBJ_id_smime_aa_receiptRequest */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x02,  /* [ 1386] OBJ_id_smime_aa_securityLabel */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x03,  /* [ 1397] OBJ_id_smime_aa_mlExpandHistory */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x04,  /* [ 1408] OBJ_id_smime_aa_contentHint */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x05,  /* [ 1419] OBJ_id_smime_aa_msgSigDigest */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x06,  /* [ 1430] OBJ_id_smime_aa_encapContentType */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x07,  /* [ 1441] OBJ_id_smime_aa_contentIdentifier */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x08,  /* [ 1452] OBJ_id_smime_aa_macValue */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x09,  /* [ 1463] OBJ_id_smime_aa_equivalentLabels */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x0A,  /* [ 1474] OBJ_id_smime_aa_contentReference */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x0B,  /* [ 1485] OBJ_id_smime_aa_encrypKeyPref */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x0C,  /* [ 1496] OBJ_id_smime_aa_signingCertificate */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x0D,  /* [ 1507] OBJ_id_smime_aa_smimeEncryptCerts */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x0E,  /* [ 1518] OBJ_id_smime_aa_timeStampToken */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x0F,  /* [ 1529] OBJ_id_smime_aa_ets_sigPolicyId */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x10,  /* [ 1540] OBJ_id_smime_aa_ets_commitmentType */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x11,  /* [ 1551] OBJ_id_smime_aa_ets_signerLocation */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x12,  /* [ 1562] OBJ_id_smime_aa_ets_signerAttr */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x13,  /* [ 1573] OBJ_id_smime_aa_ets_otherSigCert */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x14,  /* [ 1584] OBJ_id_smime_aa_ets_contentTimestamp */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x15,  /* [ 1595] OBJ_id_smime_aa_ets_CertificateRefs */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x16,  /* [ 1606] OBJ_id_smime_aa_ets_RevocationRefs */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x17,  /* [ 1617] OBJ_id_smime_aa_ets_certValues */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x18,  /* [ 1628] OBJ_id_smime_aa_ets_revocationValues */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x19,  /* [ 1639] OBJ_id_smime_aa_ets_escTimeStamp */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x1A,  /* [ 1650] OBJ_id_smime_aa_ets_certCRLTimestamp */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x1B,  /* [ 1661] OBJ_id_smime_aa_ets_archiveTimeStamp */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x1C,  /* [ 1672] OBJ_id_smime_aa_signatureType */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x1D,  /* [ 1683] OBJ_id_smime_aa_dvcs_dvc */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,0x01,  /* [ 1694] OBJ_id_smime_alg_ESDHwith3DES */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,0x02,  /* [ 1705] OBJ_id_smime_alg_ESDHwithRC2 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,0x03,  /* [ 1716] OBJ_id_smime_alg_3DESwrap */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,0x04,  /* [ 1727] OBJ_id_smime_alg_RC2wrap */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,0x05,  /* [ 1738] OBJ_id_smime_alg_ESDH */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,0x06,  /* [ 1749] OBJ_id_smime_alg_CMS3DESwrap */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,0x07,  /* [ 1760] OBJ_id_smime_alg_CMSRC2wrap */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x04,0x01,  /* [ 1771] OBJ_id_smime_cd_ldap */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x05,0x01,  /* [ 1782] OBJ_id_smime_spq_ets_sqt_uri */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x05,0x02,  /* [ 1793] OBJ_id_smime_spq_ets_sqt_unotice */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x06,0x01,  /* [ 1804] OBJ_id_smime_cti_ets_proofOfOrigin */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x06,0x02,  /* [ 1815] OBJ_id_smime_cti_ets_proofOfReceipt */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x06,0x03,  /* [ 1826] OBJ_id_smime_cti_ets_proofOfDelivery */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x06,0x04,  /* [ 1837] OBJ_id_smime_cti_ets_proofOfSender */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x06,0x05,  /* [ 1848] OBJ_id_smime_cti_ets_proofOfApproval */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x06,0x06,  /* [ 1859] OBJ_id_smime_cti_ets_proofOfCreation */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x04,       /* [ 1870] OBJ_md4 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,            /* [ 1878] OBJ_id_pkix_mod */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x02,            /* [ 1885] OBJ_id_qt */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,            /* [ 1892] OBJ_id_it */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,            /* [ 1899] OBJ_id_pkip */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x06,            /* [ 1906] OBJ_id_alg */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,            /* [ 1913] OBJ_id_cmc */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x08,            /* [ 1920] OBJ_id_on */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x09,            /* [ 1927] OBJ_id_pda */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0A,            /* [ 1934] OBJ_id_aca */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0B,            /* [ 1941] OBJ_id_qcs */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0C,            /* [ 1948] OBJ_id_cct */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x01,       /* [ 1955] OBJ_id_pkix1_explicit_88 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x02,       /* [ 1963] OBJ_id_pkix1_implicit_88 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x03,       /* [ 1971] OBJ_id_pkix1_explicit_93 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x04,       /* [ 1979] OBJ_id_pkix1_implicit_93 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x05,       /* [ 1987] OBJ_id_mod_crmf */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x06,       /* [ 1995] OBJ_id_mod_cmc */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x07,       /* [ 2003] OBJ_id_mod_kea_profile_88 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x08,       /* [ 2011] OBJ_id_mod_kea_profile_93 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x09,       /* [ 2019] OBJ_id_mod_cmp */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x0A,       /* [ 2027] OBJ_id_mod_qualified_cert_88 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x0B,       /* [ 2035] OBJ_id_mod_qualified_cert_93 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x0C,       /* [ 2043] OBJ_id_mod_attribute_cert */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x0D,       /* [ 2051] OBJ_id_mod_timestamp_protocol */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x0E,       /* [ 2059] OBJ_id_mod_ocsp */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x0F,       /* [ 2067] OBJ_id_mod_dvcs */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x00,0x10,       /* [ 2075] OBJ_id_mod_cmp2000 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x02,       /* [ 2083] OBJ_biometricInfo */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x03,       /* [ 2091] OBJ_qcStatements */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x04,       /* [ 2099] OBJ_ac_auditEntity */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x05,       /* [ 2107] OBJ_ac_targeting */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x06,       /* [ 2115] OBJ_aaControls */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x07,       /* [ 2123] OBJ_sbgp_ipAddrBlock */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x08,       /* [ 2131] OBJ_sbgp_autonomousSysNum */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x09,       /* [ 2139] OBJ_sbgp_routerIdentifier */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x02,0x03,       /* [ 2147] OBJ_textNotice */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x05,       /* [ 2155] OBJ_ipsecEndSystem */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x06,       /* [ 2163] OBJ_ipsecTunnel */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x07,       /* [ 2171] OBJ_ipsecUser */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x0A,       /* [ 2179] OBJ_dvcs */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x01,       /* [ 2187] OBJ_id_it_caProtEncCert */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x02,       /* [ 2195] OBJ_id_it_signKeyPairTypes */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x03,       /* [ 2203] OBJ_id_it_encKeyPairTypes */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x04,       /* [ 2211] OBJ_id_it_preferredSymmAlg */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x05,       /* [ 2219] OBJ_id_it_caKeyUpdateInfo */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x06,       /* [ 2227] OBJ_id_it_currentCRL */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x07,       /* [ 2235] OBJ_id_it_unsupportedOIDs */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x08,       /* [ 2243] OBJ_id_it_subscriptionRequest */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x09,       /* [ 2251] OBJ_id_it_subscriptionResponse */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x0A,       /* [ 2259] OBJ_id_it_keyPairParamReq */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x0B,       /* [ 2267] OBJ_id_it_keyPairParamRep */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x0C,       /* [ 2275] OBJ_id_it_revPassphrase */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x0D,       /* [ 2283] OBJ_id_it_implicitConfirm */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x0E,       /* [ 2291] OBJ_id_it_confirmWaitTime */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x0F,       /* [ 2299] OBJ_id_it_origPKIMessage */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x01,       /* [ 2307] OBJ_id_regCtrl */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x02,       /* [ 2315] OBJ_id_regInfo */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x01,0x01,  /* [ 2323] OBJ_id_regCtrl_regToken */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x01,0x02,  /* [ 2332] OBJ_id_regCtrl_authenticator */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x01,0x03,  /* [ 2341] OBJ_id_regCtrl_pkiPublicationInfo */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x01,0x04,  /* [ 2350] OBJ_id_regCtrl_pkiArchiveOptions */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x01,0x05,  /* [ 2359] OBJ_id_regCtrl_oldCertID */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x01,0x06,  /* [ 2368] OBJ_id_regCtrl_protocolEncrKey */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x02,0x01,  /* [ 2377] OBJ_id_regInfo_utf8Pairs */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x05,0x02,0x02,  /* [ 2386] OBJ_id_regInfo_certReq */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x06,0x01,       /* [ 2395] OBJ_id_alg_des40 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x06,0x02,       /* [ 2403] OBJ_id_alg_noSignature */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x06,0x03,       /* [ 2411] OBJ_id_alg_dh_sig_hmac_sha1 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x06,0x04,       /* [ 2419] OBJ_id_alg_dh_pop */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x01,       /* [ 2427] OBJ_id_cmc_statusInfo */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x02,       /* [ 2435] OBJ_id_cmc_identification */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x03,       /* [ 2443] OBJ_id_cmc_identityProof */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x04,       /* [ 2451] OBJ_id_cmc_dataReturn */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x05,       /* [ 2459] OBJ_id_cmc_transactionId */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x06,       /* [ 2467] OBJ_id_cmc_senderNonce */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x07,       /* [ 2475] OBJ_id_cmc_recipientNonce */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x08,       /* [ 2483] OBJ_id_cmc_addExtensions */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x09,       /* [ 2491] OBJ_id_cmc_encryptedPOP */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x0A,       /* [ 2499] OBJ_id_cmc_decryptedPOP */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x0B,       /* [ 2507] OBJ_id_cmc_lraPOPWitness */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x0F,       /* [ 2515] OBJ_id_cmc_getCert */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x10,       /* [ 2523] OBJ_id_cmc_getCRL */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x11,       /* [ 2531] OBJ_id_cmc_revokeRequest */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x12,       /* [ 2539] OBJ_id_cmc_regInfo */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x13,       /* [ 2547] OBJ_id_cmc_responseInfo */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x15,       /* [ 2555] OBJ_id_cmc_queryPending */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x16,       /* [ 2563] OBJ_id_cmc_popLinkRandom */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x17,       /* [ 2571] OBJ_id_cmc_popLinkWitness */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x07,0x18,       /* [ 2579] OBJ_id_cmc_confirmCertAcceptance */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x08,0x01,       /* [ 2587] OBJ_id_on_personalData */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x09,0x01,       /* [ 2595] OBJ_id_pda_dateOfBirth */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x09,0x02,       /* [ 2603] OBJ_id_pda_placeOfBirth */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x09,0x03,       /* [ 2611] OBJ_id_pda_gender */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x09,0x04,       /* [ 2619] OBJ_id_pda_countryOfCitizenship */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x09,0x05,       /* [ 2627] OBJ_id_pda_countryOfResidence */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0A,0x01,       /* [ 2635] OBJ_id_aca_authenticationInfo */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0A,0x02,       /* [ 2643] OBJ_id_aca_accessIdentity */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0A,0x03,       /* [ 2651] OBJ_id_aca_chargingIdentity */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0A,0x04,       /* [ 2659] OBJ_id_aca_group */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0A,0x05,       /* [ 2667] OBJ_id_aca_role */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0B,0x01,       /* [ 2675] OBJ_id_qcs_pkixQCSyntax_v1 */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0C,0x01,       /* [ 2683] OBJ_id_cct_crs */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0C,0x02,       /* [ 2691] OBJ_id_cct_PKIData */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0C,0x03,       /* [ 2699] OBJ_id_cct_PKIResponse */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x03,       /* [ 2707] OBJ_ad_timeStamping */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x04,       /* [ 2715] OBJ_ad_dvcs */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x01,  /* [ 2723] OBJ_id_pkix_OCSP_basic */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x02,  /* [ 2732] OBJ_id_pkix_OCSP_Nonce */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x03,  /* [ 2741] OBJ_id_pkix_OCSP_CrlID */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x04,  /* [ 2750] OBJ_id_pkix_OCSP_acceptableResponses */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x05,  /* [ 2759] OBJ_id_pkix_OCSP_noCheck */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x06,  /* [ 2768] OBJ_id_pkix_OCSP_archiveCutoff */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x07,  /* [ 2777] OBJ_id_pkix_OCSP_serviceLocator */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x08,  /* [ 2786] OBJ_id_pkix_OCSP_extendedStatus */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x09,  /* [ 2795] OBJ_id_pkix_OCSP_valid */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x0A,  /* [ 2804] OBJ_id_pkix_OCSP_path */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x01,0x0B,  /* [ 2813] OBJ_id_pkix_OCSP_trustRoot */
    0x2B,0x0E,0x03,0x02,                           /* [ 2822] OBJ_algorithm */
    0x2B,0x0E,0x03,0x02,0x0B,                      /* [ 2826] OBJ_rsaSignature */
    0x55,0x08,                                     /* [ 2831] OBJ_X500algorithms */
    0x2B,                                          /* [ 2833] OBJ_org */
    0x2B,0x06,                                     /* [ 2834] OBJ_dod */
    0x2B,0x06,0x01,                                /* [ 2836] OBJ_iana */
    0x2B,0x06,0x01,0x01,                           /* [ 2839] OBJ_Directory */
    0x2B,0x06,0x01,0x02,                           /* [ 2843] OBJ_Management */
    0x2B,0x06,0x01,0x03,                           /* [ 2847] OBJ_Experimental */
    0x2B,0x06,0x01,0x04,                           /* [ 2851] OBJ_Private */
    0x2B,0x06,0x01,0x05,                           /* [ 2855] OBJ_Security */
    0x2B,0x06,0x01,0x06,                           /* [ 2859] OBJ_SNMPv2 */
    0x2B,0x06,0x01,0x07,                           /* [ 2863] OBJ_Mail */
    0x2B,0x06,0x01,0x04,0x01,                      /* [ 2867] OBJ_Enterprises */
    0x2B,0x06,0x01,0x04,0x01,0x8B,0x3A,0x82,0x58,  /* [ 2872] OBJ_dcObject */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x19,  /* [ 2881] OBJ_domainComponent */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x0D,  /* [ 2891] OBJ_Domain */
    0x55,0x01,0x05,                                /* [ 2901] OBJ_selected_attribute_types */
    0x55,0x01,0x05,0x37,                           /* [ 2904] OBJ_clearance */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x03,  /* [ 2908] OBJ_md4WithRSAEncryption */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x0A,       /* [ 2917] OBJ_ac_proxying */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x0B,       /* [ 2925] OBJ_sinfo_access */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x0A,0x06,       /* [ 2933] OBJ_id_aca_encAttrs */
    0x55,0x04,0x48,                                /* [ 2941] OBJ_role */
    0x55,0x1D,0x24,                                /* [ 2944] OBJ_policy_constraints */
    0x55,0x1D,0x37,                                /* [ 2947] OBJ_target_information */
    0x55,0x1D,0x38,                                /* [ 2950] OBJ_no_rev_avail */
    0x2A,0x86,0x48,0xCE,0x3D,                      /* [ 2953] OBJ_ansi_X9_62 */
    0x2A,0x86,0x48,0xCE,0x3D,0x01,0x01,            /* [ 2958] OBJ_X9_62_prime_field */
    0x2A,0x86,0x48,0xCE,0x3D,0x01,0x02,            /* [ 2965] OBJ_X9_62_characteristic_two_field */
    0x2A,0x86,0x48,0xCE,0x3D,0x02,0x01,            /* [ 2972] OBJ_X9_62_id_ecPublicKey */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x01,       /* [ 2979] OBJ_X9_62_prime192v1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x02,       /* [ 2987] OBJ_X9_62_prime192v2 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x03,       /* [ 2995] OBJ_X9_62_prime192v3 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x04,       /* [ 3003] OBJ_X9_62_prime239v1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x05,       /* [ 3011] OBJ_X9_62_prime239v2 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x06,       /* [ 3019] OBJ_X9_62_prime239v3 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x07,       /* [ 3027] OBJ_X9_62_prime256v1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x04,0x01,            /* [ 3035] OBJ_ecdsa_with_SHA1 */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x11,0x01,  /* [ 3042] OBJ_ms_csp_name */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x01,  /* [ 3051] OBJ_aes_128_ecb */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x02,  /* [ 3060] OBJ_aes_128_cbc */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x03,  /* [ 3069] OBJ_aes_128_ofb128 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x04,  /* [ 3078] OBJ_aes_128_cfb128 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x15,  /* [ 3087] OBJ_aes_192_ecb */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x16,  /* [ 3096] OBJ_aes_192_cbc */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x17,  /* [ 3105] OBJ_aes_192_ofb128 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x18,  /* [ 3114] OBJ_aes_192_cfb128 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x29,  /* [ 3123] OBJ_aes_256_ecb */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x2A,  /* [ 3132] OBJ_aes_256_cbc */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x2B,  /* [ 3141] OBJ_aes_256_ofb128 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x2C,  /* [ 3150] OBJ_aes_256_cfb128 */
    0x55,0x1D,0x17,                                /* [ 3159] OBJ_hold_instruction_code */
    0x2A,0x86,0x48,0xCE,0x38,0x02,0x01,            /* [ 3162] OBJ_hold_instruction_none */
    0x2A,0x86,0x48,0xCE,0x38,0x02,0x02,            /* [ 3169] OBJ_hold_instruction_call_issuer */
    0x2A,0x86,0x48,0xCE,0x38,0x02,0x03,            /* [ 3176] OBJ_hold_instruction_reject */
    0x09,                                          /* [ 3183] OBJ_data */
    0x09,0x92,0x26,                                /* [ 3184] OBJ_pss */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,            /* [ 3187] OBJ_ucl */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,       /* [ 3194] OBJ_pilot */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,  /* [ 3202] OBJ_pilotAttributeType */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x03,  /* [ 3211] OBJ_pilotAttributeSyntax */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,  /* [ 3220] OBJ_pilotObjectClass */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x0A,  /* [ 3229] OBJ_pilotGroups */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x03,0x04,  /* [ 3238] OBJ_iA5StringSyntax */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x03,0x05,  /* [ 3248] OBJ_caseIgnoreIA5StringSyntax */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x03,  /* [ 3258] OBJ_pilotObject */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x04,  /* [ 3268] OBJ_pilotPerson */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x05,  /* [ 3278] OBJ_account */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x06,  /* [ 3288] OBJ_document */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x07,  /* [ 3298] OBJ_room */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x09,  /* [ 3308] OBJ_documentSeries */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x0E,  /* [ 3318] OBJ_rFC822localPart */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x0F,  /* [ 3328] OBJ_dNSDomain */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x11,  /* [ 3338] OBJ_domainRelatedObject */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x12,  /* [ 3348] OBJ_friendlyCountry */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x13,  /* [ 3358] OBJ_simpleSecurityObject */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x14,  /* [ 3368] OBJ_pilotOrganization */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x15,  /* [ 3378] OBJ_pilotDSA */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x04,0x16,  /* [ 3388] OBJ_qualityLabelledData */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x01,  /* [ 3398] OBJ_userId */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x02,  /* [ 3408] OBJ_textEncodedORAddress */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x03,  /* [ 3418] OBJ_rfc822Mailbox */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x04,  /* [ 3428] OBJ_info */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x05,  /* [ 3438] OBJ_favouriteDrink */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x06,  /* [ 3448] OBJ_roomNumber */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x07,  /* [ 3458] OBJ_photo */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x08,  /* [ 3468] OBJ_userClass */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x09,  /* [ 3478] OBJ_host */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x0A,  /* [ 3488] OBJ_manager */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x0B,  /* [ 3498] OBJ_documentIdentifier */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x0C,  /* [ 3508] OBJ_documentTitle */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x0D,  /* [ 3518] OBJ_documentVersion */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x0E,  /* [ 3528] OBJ_documentAuthor */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x0F,  /* [ 3538] OBJ_documentLocation */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x14,  /* [ 3548] OBJ_homeTelephoneNumber */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x15,  /* [ 3558] OBJ_secretary */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x16,  /* [ 3568] OBJ_otherMailbox */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x17,  /* [ 3578] OBJ_lastModifiedTime */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x18,  /* [ 3588] OBJ_lastModifiedBy */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x1A,  /* [ 3598] OBJ_aRecord */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x1B,  /* [ 3608] OBJ_pilotAttributeType27 */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x1C,  /* [ 3618] OBJ_mXRecord */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x1D,  /* [ 3628] OBJ_nSRecord */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x1E,  /* [ 3638] OBJ_sOARecord */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x1F,  /* [ 3648] OBJ_cNAMERecord */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x25,  /* [ 3658] OBJ_associatedDomain */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x26,  /* [ 3668] OBJ_associatedName */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x27,  /* [ 3678] OBJ_homePostalAddress */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x28,  /* [ 3688] OBJ_personalTitle */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x29,  /* [ 3698] OBJ_mobileTelephoneNumber */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x2A,  /* [ 3708] OBJ_pagerTelephoneNumber */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x2B,  /* [ 3718] OBJ_friendlyCountryName */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x2D,  /* [ 3728] OBJ_organizationalStatus */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x2E,  /* [ 3738] OBJ_janetMailbox */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x2F,  /* [ 3748] OBJ_mailPreferenceOption */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x30,  /* [ 3758] OBJ_buildingName */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x31,  /* [ 3768] OBJ_dSAQuality */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x32,  /* [ 3778] OBJ_singleLevelQuality */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x33,  /* [ 3788] OBJ_subtreeMinimumQuality */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x34,  /* [ 3798] OBJ_subtreeMaximumQuality */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x35,  /* [ 3808] OBJ_personalSignature */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x36,  /* [ 3818] OBJ_dITRedirect */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x37,  /* [ 3828] OBJ_audio */
    0x09,0x92,0x26,0x89,0x93,0xF2,0x2C,0x64,0x01,0x38,  /* [ 3838] OBJ_documentPublisher */
    0x55,0x04,0x2D,                                /* [ 3848] OBJ_x500UniqueIdentifier */
    0x2B,0x06,0x01,0x07,0x01,                      /* [ 3851] OBJ_mime_mhs */
    0x2B,0x06,0x01,0x07,0x01,0x01,                 /* [ 3856] OBJ_mime_mhs_headings */
    0x2B,0x06,0x01,0x07,0x01,0x02,                 /* [ 3862] OBJ_mime_mhs_bodies */
    0x2B,0x06,0x01,0x07,0x01,0x01,0x01,            /* [ 3868] OBJ_id_hex_partial_message */
    0x2B,0x06,0x01,0x07,0x01,0x01,0x02,            /* [ 3875] OBJ_id_hex_multipart_message */
    0x55,0x04,0x2C,                                /* [ 3882] OBJ_generationQualifier */
    0x55,0x04,0x41,                                /* [ 3885] OBJ_pseudonym */
    0x67,0x2A,                                     /* [ 3888] OBJ_id_set */
    0x67,0x2A,0x00,                                /* [ 3890] OBJ_set_ctype */
    0x67,0x2A,0x01,                                /* [ 3893] OBJ_set_msgExt */
    0x67,0x2A,0x03,                                /* [ 3896] OBJ_set_attr */
    0x67,0x2A,0x05,                                /* [ 3899] OBJ_set_policy */
    0x67,0x2A,0x07,                                /* [ 3902] OBJ_set_certExt */
    0x67,0x2A,0x08,                                /* [ 3905] OBJ_set_brand */
    0x67,0x2A,0x00,0x00,                           /* [ 3908] OBJ_setct_PANData */
    0x67,0x2A,0x00,0x01,                           /* [ 3912] OBJ_setct_PANToken */
    0x67,0x2A,0x00,0x02,                           /* [ 3916] OBJ_setct_PANOnly */
    0x67,0x2A,0x00,0x03,                           /* [ 3920] OBJ_setct_OIData */
    0x67,0x2A,0x00,0x04,                           /* [ 3924] OBJ_setct_PI */
    0x67,0x2A,0x00,0x05,                           /* [ 3928] OBJ_setct_PIData */
    0x67,0x2A,0x00,0x06,                           /* [ 3932] OBJ_setct_PIDataUnsigned */
    0x67,0x2A,0x00,0x07,                           /* [ 3936] OBJ_setct_HODInput */
    0x67,0x2A,0x00,0x08,                           /* [ 3940] OBJ_setct_AuthResBaggage */
    0x67,0x2A,0x00,0x09,                           /* [ 3944] OBJ_setct_AuthRevReqBaggage */
    0x67,0x2A,0x00,0x0A,                           /* [ 3948] OBJ_setct_AuthRevResBaggage */
    0x67,0x2A,0x00,0x0B,                           /* [ 3952] OBJ_setct_CapTokenSeq */
    0x67,0x2A,0x00,0x0C,                           /* [ 3956] OBJ_setct_PInitResData */
    0x67,0x2A,0x00,0x0D,                           /* [ 3960] OBJ_setct_PI_TBS */
    0x67,0x2A,0x00,0x0E,                           /* [ 3964] OBJ_setct_PResData */
    0x67,0x2A,0x00,0x10,                           /* [ 3968] OBJ_setct_AuthReqTBS */
    0x67,0x2A,0x00,0x11,                           /* [ 3972] OBJ_setct_AuthResTBS */
    0x67,0x2A,0x00,0x12,                           /* [ 3976] OBJ_setct_AuthResTBSX */
    0x67,0x2A,0x00,0x13,                           /* [ 3980] OBJ_setct_AuthTokenTBS */
    0x67,0x2A,0x00,0x14,                           /* [ 3984] OBJ_setct_CapTokenData */
    0x67,0x2A,0x00,0x15,                           /* [ 3988] OBJ_setct_CapTokenTBS */
    0x67,0x2A,0x00,0x16,                           /* [ 3992] OBJ_setct_AcqCardCodeMsg */
    0x67,0x2A,0x00,0x17,                           /* [ 3996] OBJ_setct_AuthRevReqTBS */
    0x67,0x2A,0x00,0x18,                           /* [ 4000] OBJ_setct_AuthRevResData */
    0x67,0x2A,0x00,0x19,                           /* [ 4004] OBJ_setct_AuthRevResTBS */
    0x67,0x2A,0x00,0x1A,                           /* [ 4008] OBJ_setct_CapReqTBS */
    0x67,0x2A,0x00,0x1B,                           /* [ 4012] OBJ_setct_CapReqTBSX */
    0x67,0x2A,0x00,0x1C,                           /* [ 4016] OBJ_setct_CapResData */
    0x67,0x2A,0x00,0x1D,                           /* [ 4020] OBJ_setct_CapRevReqTBS */
    0x67,0x2A,0x00,0x1E,                           /* [ 4024] OBJ_setct_CapRevReqTBSX */
    0x67,0x2A,0x00,0x1F,                           /* [ 4028] OBJ_setct_CapRevResData */
    0x67,0x2A,0x00,0x20,                           /* [ 4032] OBJ_setct_CredReqTBS */
    0x67,0x2A,0x00,0x21,                           /* [ 4036] OBJ_setct_CredReqTBSX */
    0x67,0x2A,0x00,0x22,                           /* [ 4040] OBJ_setct_CredResData */
    0x67,0x2A,0x00,0x23,                           /* [ 4044] OBJ_setct_CredRevReqTBS */
    0x67,0x2A,0x00,0x24,                           /* [ 4048] OBJ_setct_CredRevReqTBSX */
    0x67,0x2A,0x00,0x25,                           /* [ 4052] OBJ_setct_CredRevResData */
    0x67,0x2A,0x00,0x26,                           /* [ 4056] OBJ_setct_PCertReqData */
    0x67,0x2A,0x00,0x27,                           /* [ 4060] OBJ_setct_PCertResTBS */
    0x67,0x2A,0x00,0x28,                           /* [ 4064] OBJ_setct_BatchAdminReqData */
    0x67,0x2A,0x00,0x29,                           /* [ 4068] OBJ_setct_BatchAdminResData */
    0x67,0x2A,0x00,0x2A,                           /* [ 4072] OBJ_setct_CardCInitResTBS */
    0x67,0x2A,0x00,0x2B,                           /* [ 4076] OBJ_setct_MeAqCInitResTBS */
    0x67,0x2A,0x00,0x2C,                           /* [ 4080] OBJ_setct_RegFormResTBS */
    0x67,0x2A,0x00,0x2D,                           /* [ 4084] OBJ_setct_CertReqData */
    0x67,0x2A,0x00,0x2E,                           /* [ 4088] OBJ_setct_CertReqTBS */
    0x67,0x2A,0x00,0x2F,                           /* [ 4092] OBJ_setct_CertResData */
    0x67,0x2A,0x00,0x30,                           /* [ 4096] OBJ_setct_CertInqReqTBS */
    0x67,0x2A,0x00,0x31,                           /* [ 4100] OBJ_setct_ErrorTBS */
    0x67,0x2A,0x00,0x32,                           /* [ 4104] OBJ_setct_PIDualSignedTBE */
    0x67,0x2A,0x00,0x33,                           /* [ 4108] OBJ_setct_PIUnsignedTBE */
    0x67,0x2A,0x00,0x34,                           /* [ 4112] OBJ_setct_AuthReqTBE */
    0x67,0x2A,0x00,0x35,                           /* [ 4116] OBJ_setct_AuthResTBE */
    0x67,0x2A,0x00,0x36,                           /* [ 4120] OBJ_setct_AuthResTBEX */
    0x67,0x2A,0x00,0x37,                           /* [ 4124] OBJ_setct_AuthTokenTBE */
    0x67,0x2A,0x00,0x38,                           /* [ 4128] OBJ_setct_CapTokenTBE */
    0x67,0x2A,0x00,0x39,                           /* [ 4132] OBJ_setct_CapTokenTBEX */
    0x67,0x2A,0x00,0x3A,                           /* [ 4136] OBJ_setct_AcqCardCodeMsgTBE */
    0x67,0x2A,0x00,0x3B,                           /* [ 4140] OBJ_setct_AuthRevReqTBE */
    0x67,0x2A,0x00,0x3C,                           /* [ 4144] OBJ_setct_AuthRevResTBE */
    0x67,0x2A,0x00,0x3D,                           /* [ 4148] OBJ_setct_AuthRevResTBEB */
    0x67,0x2A,0x00,0x3E,                           /* [ 4152] OBJ_setct_CapReqTBE */
    0x67,0x2A,0x00,0x3F,                           /* [ 4156] OBJ_setct_CapReqTBEX */
    0x67,0x2A,0x00,0x40,                           /* [ 4160] OBJ_setct_CapResTBE */
    0x67,0x2A,0x00,0x41,                           /* [ 4164] OBJ_setct_CapRevReqTBE */
    0x67,0x2A,0x00,0x42,                           /* [ 4168] OBJ_setct_CapRevReqTBEX */
    0x67,0x2A,0x00,0x43,                           /* [ 4172] OBJ_setct_CapRevResTBE */
    0x67,0x2A,0x00,0x44,                           /* [ 4176] OBJ_setct_CredReqTBE */
    0x67,0x2A,0x00,0x45,                           /* [ 4180] OBJ_setct_CredReqTBEX */
    0x67,0x2A,0x00,0x46,                           /* [ 4184] OBJ_setct_CredResTBE */
    0x67,0x2A,0x00,0x47,                           /* [ 4188] OBJ_setct_CredRevReqTBE */
    0x67,0x2A,0x00,0x48,                           /* [ 4192] OBJ_setct_CredRevReqTBEX */
    0x67,0x2A,0x00,0x49,                           /* [ 4196] OBJ_setct_CredRevResTBE */
    0x67,0x2A,0x00,0x4A,                           /* [ 4200] OBJ_setct_BatchAdminReqTBE */
    0x67,0x2A,0x00,0x4B,                           /* [ 4204] OBJ_setct_BatchAdminResTBE */
    0x67,0x2A,0x00,0x4C,                           /* [ 4208] OBJ_setct_RegFormReqTBE */
    0x67,0x2A,0x00,0x4D,                           /* [ 4212] OBJ_setct_CertReqTBE */
    0x67,0x2A,0x00,0x4E,                           /* [ 4216] OBJ_setct_CertReqTBEX */
    0x67,0x2A,0x00,0x4F,                           /* [ 4220] OBJ_setct_CertResTBE */
    0x67,0x2A,0x00,0x50,                           /* [ 4224] OBJ_setct_CRLNotificationTBS */
    0x67,0x2A,0x00,0x51,                           /* [ 4228] OBJ_setct_CRLNotificationResTBS */
    0x67,0x2A,0x00,0x52,                           /* [ 4232] OBJ_setct_BCIDistributionTBS */
    0x67,0x2A,0x01,0x01,                           /* [ 4236] OBJ_setext_genCrypt */
    0x67,0x2A,0x01,0x03,                           /* [ 4240] OBJ_setext_miAuth */
    0x67,0x2A,0x01,0x04,                           /* [ 4244] OBJ_setext_pinSecure */
    0x67,0x2A,0x01,0x05,                           /* [ 4248] OBJ_setext_pinAny */
    0x67,0x2A,0x01,0x07,                           /* [ 4252] OBJ_setext_track2 */
    0x67,0x2A,0x01,0x08,                           /* [ 4256] OBJ_setext_cv */
    0x67,0x2A,0x05,0x00,                           /* [ 4260] OBJ_set_policy_root */
    0x67,0x2A,0x07,0x00,                           /* [ 4264] OBJ_setCext_hashedRoot */
    0x67,0x2A,0x07,0x01,                           /* [ 4268] OBJ_setCext_certType */
    0x67,0x2A,0x07,0x02,                           /* [ 4272] OBJ_setCext_merchData */
    0x67,0x2A,0x07,0x03,                           /* [ 4276] OBJ_setCext_cCertRequired */
    0x67,0x2A,0x07,0x04,                           /* [ 4280] OBJ_setCext_tunneling */
    0x67,0x2A,0x07,0x05,                           /* [ 4284] OBJ_setCext_setExt */
    0x67,0x2A,0x07,0x06,                           /* [ 4288] OBJ_setCext_setQualf */
    0x67,0x2A,0x07,0x07,                           /* [ 4292] OBJ_setCext_PGWYcapabilities */
    0x67,0x2A,0x07,0x08,                           /* [ 4296] OBJ_setCext_TokenIdentifier */
    0x67,0x2A,0x07,0x09,                           /* [ 4300] OBJ_setCext_Track2Data */
    0x67,0x2A,0x07,0x0A,                           /* [ 4304] OBJ_setCext_TokenType */
    0x67,0x2A,0x07,0x0B,                           /* [ 4308] OBJ_setCext_IssuerCapabilities */
    0x67,0x2A,0x03,0x00,                           /* [ 4312] OBJ_setAttr_Cert */
    0x67,0x2A,0x03,0x01,                           /* [ 4316] OBJ_setAttr_PGWYcap */
    0x67,0x2A,0x03,0x02,                           /* [ 4320] OBJ_setAttr_TokenType */
    0x67,0x2A,0x03,0x03,                           /* [ 4324] OBJ_setAttr_IssCap */
    0x67,0x2A,0x03,0x00,0x00,                      /* [ 4328] OBJ_set_rootKeyThumb */
    0x67,0x2A,0x03,0x00,0x01,                      /* [ 4333] OBJ_set_addPolicy */
    0x67,0x2A,0x03,0x02,0x01,                      /* [ 4338] OBJ_setAttr_Token_EMV */
    0x67,0x2A,0x03,0x02,0x02,                      /* [ 4343] OBJ_setAttr_Token_B0Prime */
    0x67,0x2A,0x03,0x03,0x03,                      /* [ 4348] OBJ_setAttr_IssCap_CVM */
    0x67,0x2A,0x03,0x03,0x04,                      /* [ 4353] OBJ_setAttr_IssCap_T2 */
    0x67,0x2A,0x03,0x03,0x05,                      /* [ 4358] OBJ_setAttr_IssCap_Sig */
    0x67,0x2A,0x03,0x03,0x03,0x01,                 /* [ 4363] OBJ_setAttr_GenCryptgrm */
    0x67,0x2A,0x03,0x03,0x04,0x01,                 /* [ 4369] OBJ_setAttr_T2Enc */
    0x67,0x2A,0x03,0x03,0x04,0x02,                 /* [ 4375] OBJ_setAttr_T2cleartxt */
    0x67,0x2A,0x03,0x03,0x05,0x01,                 /* [ 4381] OBJ_setAttr_TokICCsig */
    0x67,0x2A,0x03,0x03,0x05,0x02,                 /* [ 4387] OBJ_setAttr_SecDevSig */
    0x67,0x2A,0x08,0x01,                           /* [ 4393] OBJ_set_brand_IATA_ATA */
    0x67,0x2A,0x08,0x1E,                           /* [ 4397] OBJ_set_brand_Diners */
    0x67,0x2A,0x08,0x22,                           /* [ 4401] OBJ_set_brand_AmericanExpress */
    0x67,0x2A,0x08,0x23,                           /* [ 4405] OBJ_set_brand_JCB */
    0x67,0x2A,0x08,0x04,                           /* [ 4409] OBJ_set_brand_Visa */
    0x67,0x2A,0x08,0x05,                           /* [ 4413] OBJ_set_brand_MasterCard */
    0x67,0x2A,0x08,0xAE,0x7B,                      /* [ 4417] OBJ_set_brand_Novus */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x03,0x0A,       /* [ 4422] OBJ_des_cdmf */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x06,  /* [ 4430] OBJ_rsaOAEPEncryptionSET */
    0x67,                                          /* [ 4439] OBJ_international_organizations */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x14,0x02,0x02,  /* [ 4440] OBJ_ms_smartcard_login */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x14,0x02,0x03,  /* [ 4450] OBJ_ms_upn */
    0x55,0x04,0x09,                                /* [ 4460] OBJ_streetAddress */
    0x55,0x04,0x11,                                /* [ 4463] OBJ_postalCode */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x15,            /* [ 4466] OBJ_id_ppl */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x0E,       /* [ 4473] OBJ_proxyCertInfo */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x15,0x00,       /* [ 4481] OBJ_id_ppl_anyLanguage */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x15,0x01,       /* [ 4489] OBJ_id_ppl_inheritAll */
    0x55,0x1D,0x1E,                                /* [ 4497] OBJ_name_constraints */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x15,0x02,       /* [ 4500] OBJ_Independent */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x0B,  /* [ 4508] OBJ_sha256WithRSAEncryption */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x0C,  /* [ 4517] OBJ_sha384WithRSAEncryption */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x0D,  /* [ 4526] OBJ_sha512WithRSAEncryption */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x0E,  /* [ 4535] OBJ_sha224WithRSAEncryption */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x01,  /* [ 4544] OBJ_sha256 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x02,  /* [ 4553] OBJ_sha384 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x03,  /* [ 4562] OBJ_sha512 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x04,  /* [ 4571] OBJ_sha224 */
    0x2B,                                          /* [ 4580] OBJ_identified_organization */
    0x2B,0x81,0x04,                                /* [ 4581] OBJ_certicom_arc */
    0x67,0x2B,                                     /* [ 4584] OBJ_wap */
    0x67,0x2B,0x01,                                /* [ 4586] OBJ_wap_wsg */
    0x2A,0x86,0x48,0xCE,0x3D,0x01,0x02,0x03,       /* [ 4589] OBJ_X9_62_id_characteristic_two_basis */
    0x2A,0x86,0x48,0xCE,0x3D,0x01,0x02,0x03,0x01,  /* [ 4597] OBJ_X9_62_onBasis */
    0x2A,0x86,0x48,0xCE,0x3D,0x01,0x02,0x03,0x02,  /* [ 4606] OBJ_X9_62_tpBasis */
    0x2A,0x86,0x48,0xCE,0x3D,0x01,0x02,0x03,0x03,  /* [ 4615] OBJ_X9_62_ppBasis */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x01,       /* [ 4624] OBJ_X9_62_c2pnb163v1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x02,       /* [ 4632] OBJ_X9_62_c2pnb163v2 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x03,       /* [ 4640] OBJ_X9_62_c2pnb163v3 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x04,       /* [ 4648] OBJ_X9_62_c2pnb176v1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x05,       /* [ 4656] OBJ_X9_62_c2tnb191v1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x06,       /* [ 4664] OBJ_X9_62_c2tnb191v2 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x07,       /* [ 4672] OBJ_X9_62_c2tnb191v3 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x08,       /* [ 4680] OBJ_X9_62_c2onb191v4 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x09,       /* [ 4688] OBJ_X9_62_c2onb191v5 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x0A,       /* [ 4696] OBJ_X9_62_c2pnb208w1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x0B,       /* [ 4704] OBJ_X9_62_c2tnb239v1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x0C,       /* [ 4712] OBJ_X9_62_c2tnb239v2 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x0D,       /* [ 4720] OBJ_X9_62_c2tnb239v3 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x0E,       /* [ 4728] OBJ_X9_62_c2onb239v4 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x0F,       /* [ 4736] OBJ_X9_62_c2onb239v5 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x10,       /* [ 4744] OBJ_X9_62_c2pnb272w1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x11,       /* [ 4752] OBJ_X9_62_c2pnb304w1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x12,       /* [ 4760] OBJ_X9_62_c2tnb359v1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x13,       /* [ 4768] OBJ_X9_62_c2pnb368w1 */
    0x2A,0x86,0x48,0xCE,0x3D,0x03,0x00,0x14,       /* [ 4776] OBJ_X9_62_c2tnb431r1 */
    0x2B,0x81,0x04,0x00,0x06,                      /* [ 4784] OBJ_secp112r1 */
    0x2B,0x81,0x04,0x00,0x07,                      /* [ 4789] OBJ_secp112r2 */
    0x2B,0x81,0x04,0x00,0x1C,                      /* [ 4794] OBJ_secp128r1 */
    0x2B,0x81,0x04,0x00,0x1D,                      /* [ 4799] OBJ_secp128r2 */
    0x2B,0x81,0x04,0x00,0x09,                      /* [ 4804] OBJ_secp160k1 */
    0x2B,0x81,0x04,0x00,0x08,                      /* [ 4809] OBJ_secp160r1 */
    0x2B,0x81,0x04,0x00,0x1E,                      /* [ 4814] OBJ_secp160r2 */
    0x2B,0x81,0x04,0x00,0x1F,                      /* [ 4819] OBJ_secp192k1 */
    0x2B,0x81,0x04,0x00,0x20,                      /* [ 4824] OBJ_secp224k1 */
    0x2B,0x81,0x04,0x00,0x21,                      /* [ 4829] OBJ_secp224r1 */
    0x2B,0x81,0x04,0x00,0x0A,                      /* [ 4834] OBJ_secp256k1 */
    0x2B,0x81,0x04,0x00,0x22,                      /* [ 4839] OBJ_secp384r1 */
    0x2B,0x81,0x04,0x00,0x23,                      /* [ 4844] OBJ_secp521r1 */
    0x2B,0x81,0x04,0x00,0x04,                      /* [ 4849] OBJ_sect113r1 */
    0x2B,0x81,0x04,0x00,0x05,                      /* [ 4854] OBJ_sect113r2 */
    0x2B,0x81,0x04,0x00,0x16,                      /* [ 4859] OBJ_sect131r1 */
    0x2B,0x81,0x04,0x00,0x17,                      /* [ 4864] OBJ_sect131r2 */
    0x2B,0x81,0x04,0x00,0x01,                      /* [ 4869] OBJ_sect163k1 */
    0x2B,0x81,0x04,0x00,0x02,                      /* [ 4874] OBJ_sect163r1 */
    0x2B,0x81,0x04,0x00,0x0F,                      /* [ 4879] OBJ_sect163r2 */
    0x2B,0x81,0x04,0x00,0x18,                      /* [ 4884] OBJ_sect193r1 */
    0x2B,0x81,0x04,0x00,0x19,                      /* [ 4889] OBJ_sect193r2 */
    0x2B,0x81,0x04,0x00,0x1A,                      /* [ 4894] OBJ_sect233k1 */
    0x2B,0x81,0x04,0x00,0x1B,                      /* [ 4899] OBJ_sect233r1 */
    0x2B,0x81,0x04,0x00,0x03,                      /* [ 4904] OBJ_sect239k1 */
    0x2B,0x81,0x04,0x00,0x10,                      /* [ 4909] OBJ_sect283k1 */
    0x2B,0x81,0x04,0x00,0x11,                      /* [ 4914] OBJ_sect283r1 */
    0x2B,0x81,0x04,0x00,0x24,                      /* [ 4919] OBJ_sect409k1 */
    0x2B,0x81,0x04,0x00,0x25,                      /* [ 4924] OBJ_sect409r1 */
    0x2B,0x81,0x04,0x00,0x26,                      /* [ 4929] OBJ_sect571k1 */
    0x2B,0x81,0x04,0x00,0x27,                      /* [ 4934] OBJ_sect571r1 */
    0x67,0x2B,0x01,0x04,0x01,                      /* [ 4939] OBJ_wap_wsg_idm_ecid_wtls1 */
    0x67,0x2B,0x01,0x04,0x03,                      /* [ 4944] OBJ_wap_wsg_idm_ecid_wtls3 */
    0x67,0x2B,0x01,0x04,0x04,                      /* [ 4949] OBJ_wap_wsg_idm_ecid_wtls4 */
    0x67,0x2B,0x01,0x04,0x05,                      /* [ 4954] OBJ_wap_wsg_idm_ecid_wtls5 */
    0x67,0x2B,0x01,0x04,0x06,                      /* [ 4959] OBJ_wap_wsg_idm_ecid_wtls6 */
    0x67,0x2B,0x01,0x04,0x07,                      /* [ 4964] OBJ_wap_wsg_idm_ecid_wtls7 */
    0x67,0x2B,0x01,0x04,0x08,                      /* [ 4969] OBJ_wap_wsg_idm_ecid_wtls8 */
    0x67,0x2B,0x01,0x04,0x09,                      /* [ 4974] OBJ_wap_wsg_idm_ecid_wtls9 */
    0x67,0x2B,0x01,0x04,0x0A,                      /* [ 4979] OBJ_wap_wsg_idm_ecid_wtls10 */
    0x67,0x2B,0x01,0x04,0x0B,                      /* [ 4984] OBJ_wap_wsg_idm_ecid_wtls11 */
    0x67,0x2B,0x01,0x04,0x0C,                      /* [ 4989] OBJ_wap_wsg_idm_ecid_wtls12 */
    0x55,0x1D,0x20,0x00,                           /* [ 4994] OBJ_any_policy */
    0x55,0x1D,0x21,                                /* [ 4998] OBJ_policy_mappings */
    0x55,0x1D,0x36,                                /* [ 5001] OBJ_inhibit_any_policy */
    0x2A,0x83,0x08,0x8C,0x9A,0x4B,0x3D,0x01,0x01,0x01,0x02,  /* [ 5004] OBJ_camellia_128_cbc */
    0x2A,0x83,0x08,0x8C,0x9A,0x4B,0x3D,0x01,0x01,0x01,0x03,  /* [ 5015] OBJ_camellia_192_cbc */
    0x2A,0x83,0x08,0x8C,0x9A,0x4B,0x3D,0x01,0x01,0x01,0x04,  /* [ 5026] OBJ_camellia_256_cbc */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x01,       /* [ 5037] OBJ_camellia_128_ecb */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x15,       /* [ 5045] OBJ_camellia_192_ecb */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x29,       /* [ 5053] OBJ_camellia_256_ecb */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x04,       /* [ 5061] OBJ_camellia_128_cfb128 */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x18,       /* [ 5069] OBJ_camellia_192_cfb128 */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x2C,       /* [ 5077] OBJ_camellia_256_cfb128 */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x03,       /* [ 5085] OBJ_camellia_128_ofb128 */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x17,       /* [ 5093] OBJ_camellia_192_ofb128 */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x2B,       /* [ 5101] OBJ_camellia_256_ofb128 */
    0x55,0x1D,0x09,                                /* [ 5109] OBJ_subject_directory_attributes */
    0x55,0x1D,0x1C,                                /* [ 5112] OBJ_issuing_distribution_point */
    0x55,0x1D,0x1D,                                /* [ 5115] OBJ_certificate_issuer */
    0x2A,0x83,0x1A,0x8C,0x9A,0x44,                 /* [ 5118] OBJ_kisa */
    0x2A,0x83,0x1A,0x8C,0x9A,0x44,0x01,0x03,       /* [ 5124] OBJ_seed_ecb */
    0x2A,0x83,0x1A,0x8C,0x9A,0x44,0x01,0x04,       /* [ 5132] OBJ_seed_cbc */
    0x2A,0x83,0x1A,0x8C,0x9A,0x44,0x01,0x06,       /* [ 5140] OBJ_seed_ofb128 */
    0x2A,0x83,0x1A,0x8C,0x9A,0x44,0x01,0x05,       /* [ 5148] OBJ_seed_cfb128 */
    0x2B,0x06,0x01,0x05,0x05,0x08,0x01,0x01,       /* [ 5156] OBJ_hmac_md5 */
    0x2B,0x06,0x01,0x05,0x05,0x08,0x01,0x02,       /* [ 5164] OBJ_hmac_sha1 */
    0x2A,0x86,0x48,0x86,0xF6,0x7D,0x07,0x42,0x0D,  /* [ 5172] OBJ_id_PasswordBasedMAC */
    0x2A,0x86,0x48,0x86,0xF6,0x7D,0x07,0x42,0x1E,  /* [ 5181] OBJ_id_DHBasedMac */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x04,0x10,       /* [ 5190] OBJ_id_it_suppLangTags */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x30,0x05,       /* [ 5198] OBJ_caRepository */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x09,  /* [ 5206] OBJ_id_smime_ct_compressedData */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x1B,  /* [ 5217] OBJ_id_ct_asciiTextWithCRLF */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x05,  /* [ 5228] OBJ_id_aes128_wrap */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x19,  /* [ 5237] OBJ_id_aes192_wrap */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x2D,  /* [ 5246] OBJ_id_aes256_wrap */
    0x2A,0x86,0x48,0xCE,0x3D,0x04,0x02,            /* [ 5255] OBJ_ecdsa_with_Recommended */
    0x2A,0x86,0x48,0xCE,0x3D,0x04,0x03,            /* [ 5262] OBJ_ecdsa_with_Specified */
    0x2A,0x86,0x48,0xCE,0x3D,0x04,0x03,0x01,       /* [ 5269] OBJ_ecdsa_with_SHA224 */
    0x2A,0x86,0x48,0xCE,0x3D,0x04,0x03,0x02,       /* [ 5277] OBJ_ecdsa_with_SHA256 */
    0x2A,0x86,0x48,0xCE,0x3D,0x04,0x03,0x03,       /* [ 5285] OBJ_ecdsa_with_SHA384 */
    0x2A,0x86,0x48,0xCE,0x3D,0x04,0x03,0x04,       /* [ 5293] OBJ_ecdsa_with_SHA512 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x06,       /* [ 5301] OBJ_hmacWithMD5 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x08,       /* [ 5309] OBJ_hmacWithSHA224 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x09,       /* [ 5317] OBJ_hmacWithSHA256 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x0A,       /* [ 5325] OBJ_hmacWithSHA384 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x0B,       /* [ 5333] OBJ_hmacWithSHA512 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x01,  /* [ 5341] OBJ_dsa_with_SHA224 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x02,  /* [ 5350] OBJ_dsa_with_SHA256 */
    0x28,0xCF,0x06,0x03,0x00,0x37,                 /* [ 5359] OBJ_whirlpool */
    0x2A,0x85,0x03,0x02,0x02,                      /* [ 5365] OBJ_cryptopro */
    0x2A,0x85,0x03,0x02,0x09,                      /* [ 5370] OBJ_cryptocom */
    0x2A,0x85,0x03,0x02,0x02,0x03,                 /* [ 5375] OBJ_id_GostR3411_94_with_GostR3410_2001 */
    0x2A,0x85,0x03,0x02,0x02,0x04,                 /* [ 5381] OBJ_id_GostR3411_94_with_GostR3410_94 */
    0x2A,0x85,0x03,0x02,0x02,0x09,                 /* [ 5387] OBJ_id_GostR3411_94 */
    0x2A,0x85,0x03,0x02,0x02,0x0A,                 /* [ 5393] OBJ_id_HMACGostR3411_94 */
    0x2A,0x85,0x03,0x02,0x02,0x13,                 /* [ 5399] OBJ_id_GostR3410_2001 */
    0x2A,0x85,0x03,0x02,0x02,0x14,                 /* [ 5405] OBJ_id_GostR3410_94 */
    0x2A,0x85,0x03,0x02,0x02,0x15,                 /* [ 5411] OBJ_id_Gost28147_89 */
    0x2A,0x85,0x03,0x02,0x02,0x16,                 /* [ 5417] OBJ_id_Gost28147_89_MAC */
    0x2A,0x85,0x03,0x02,0x02,0x17,                 /* [ 5423] OBJ_id_GostR3411_94_prf */
    0x2A,0x85,0x03,0x02,0x02,0x62,                 /* [ 5429] OBJ_id_GostR3410_2001DH */
    0x2A,0x85,0x03,0x02,0x02,0x63,                 /* [ 5435] OBJ_id_GostR3410_94DH */
    0x2A,0x85,0x03,0x02,0x02,0x0E,0x01,            /* [ 5441] OBJ_id_Gost28147_89_CryptoPro_KeyMeshing */
    0x2A,0x85,0x03,0x02,0x02,0x0E,0x00,            /* [ 5448] OBJ_id_Gost28147_89_None_KeyMeshing */
    0x2A,0x85,0x03,0x02,0x02,0x1E,0x00,            /* [ 5455] OBJ_id_GostR3411_94_TestParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x1E,0x01,            /* [ 5462] OBJ_id_GostR3411_94_CryptoProParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x1F,0x00,            /* [ 5469] OBJ_id_Gost28147_89_TestParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x1F,0x01,            /* [ 5476] OBJ_id_Gost28147_89_CryptoPro_A_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x1F,0x02,            /* [ 5483] OBJ_id_Gost28147_89_CryptoPro_B_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x1F,0x03,            /* [ 5490] OBJ_id_Gost28147_89_CryptoPro_C_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x1F,0x04,            /* [ 5497] OBJ_id_Gost28147_89_CryptoPro_D_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x1F,0x05,            /* [ 5504] OBJ_id_Gost28147_89_CryptoPro_Oscar_1_1_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x1F,0x06,            /* [ 5511] OBJ_id_Gost28147_89_CryptoPro_Oscar_1_0_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x1F,0x07,            /* [ 5518] OBJ_id_Gost28147_89_CryptoPro_RIC_1_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x20,0x00,            /* [ 5525] OBJ_id_GostR3410_94_TestParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x20,0x02,            /* [ 5532] OBJ_id_GostR3410_94_CryptoPro_A_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x20,0x03,            /* [ 5539] OBJ_id_GostR3410_94_CryptoPro_B_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x20,0x04,            /* [ 5546] OBJ_id_GostR3410_94_CryptoPro_C_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x20,0x05,            /* [ 5553] OBJ_id_GostR3410_94_CryptoPro_D_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x21,0x01,            /* [ 5560] OBJ_id_GostR3410_94_CryptoPro_XchA_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x21,0x02,            /* [ 5567] OBJ_id_GostR3410_94_CryptoPro_XchB_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x21,0x03,            /* [ 5574] OBJ_id_GostR3410_94_CryptoPro_XchC_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x23,0x00,            /* [ 5581] OBJ_id_GostR3410_2001_TestParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x23,0x01,            /* [ 5588] OBJ_id_GostR3410_2001_CryptoPro_A_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x23,0x02,            /* [ 5595] OBJ_id_GostR3410_2001_CryptoPro_B_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x23,0x03,            /* [ 5602] OBJ_id_GostR3410_2001_CryptoPro_C_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x24,0x00,            /* [ 5609] OBJ_id_GostR3410_2001_CryptoPro_XchA_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x24,0x01,            /* [ 5616] OBJ_id_GostR3410_2001_CryptoPro_XchB_ParamSet */
    0x2A,0x85,0x03,0x02,0x02,0x14,0x01,            /* [ 5623] OBJ_id_GostR3410_94_a */
    0x2A,0x85,0x03,0x02,0x02,0x14,0x02,            /* [ 5630] OBJ_id_GostR3410_94_aBis */
    0x2A,0x85,0x03,0x02,0x02,0x14,0x03,            /* [ 5637] OBJ_id_GostR3410_94_b */
    0x2A,0x85,0x03,0x02,0x02,0x14,0x04,            /* [ 5644] OBJ_id_GostR3410_94_bBis */
    0x2A,0x85,0x03,0x02,0x09,0x01,0x06,0x01,       /* [ 5651] OBJ_id_Gost28147_89_cc */
    0x2A,0x85,0x03,0x02,0x09,0x01,0x05,0x03,       /* [ 5659] OBJ_id_GostR3410_94_cc */
    0x2A,0x85,0x03,0x02,0x09,0x01,0x05,0x04,       /* [ 5667] OBJ_id_GostR3410_2001_cc */
    0x2A,0x85,0x03,0x02,0x09,0x01,0x03,0x03,       /* [ 5675] OBJ_id_GostR3411_94_with_GostR3410_94_cc */
    0x2A,0x85,0x03,0x02,0x09,0x01,0x03,0x04,       /* [ 5683] OBJ_id_GostR3411_94_with_GostR3410_2001_cc */
    0x2A,0x85,0x03,0x02,0x09,0x01,0x08,0x01,       /* [ 5691] OBJ_id_GostR3410_2001_ParamSet_cc */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x11,0x02,  /* [ 5699] OBJ_LocalKeySet */
    0x55,0x1D,0x2E,                                /* [ 5708] OBJ_freshest_crl */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x08,0x03,       /* [ 5711] OBJ_id_on_permanentIdentifier */
    0x55,0x04,0x0E,                                /* [ 5719] OBJ_searchGuide */
    0x55,0x04,0x0F,                                /* [ 5722] OBJ_businessCategory */
    0x55,0x04,0x10,                                /* [ 5725] OBJ_postalAddress */
    0x55,0x04,0x12,                                /* [ 5728] OBJ_postOfficeBox */
    0x55,0x04,0x13,                                /* [ 5731] OBJ_physicalDeliveryOfficeName */
    0x55,0x04,0x14,                                /* [ 5734] OBJ_telephoneNumber */
    0x55,0x04,0x15,                                /* [ 5737] OBJ_telexNumber */
    0x55,0x04,0x16,                                /* [ 5740] OBJ_teletexTerminalIdentifier */
    0x55,0x04,0x17,                                /* [ 5743] OBJ_facsimileTelephoneNumber */
    0x55,0x04,0x18,                                /* [ 5746] OBJ_x121Address */
    0x55,0x04,0x19,                                /* [ 5749] OBJ_internationaliSDNNumber */
    0x55,0x04,0x1A,                                /* [ 5752] OBJ_registeredAddress */
    0x55,0x04,0x1B,                                /* [ 5755] OBJ_destinationIndicator */
    0x55,0x04,0x1C,                                /* [ 5758] OBJ_preferredDeliveryMethod */
    0x55,0x04,0x1D,                                /* [ 5761] OBJ_presentationAddress */
    0x55,0x04,0x1E,                                /* [ 5764] OBJ_supportedApplicationContext */
    0x55,0x04,0x1F,                                /* [ 5767] OBJ_member */
    0x55,0x04,0x20,                                /* [ 5770] OBJ_owner */
    0x55,0x04,0x21,                                /* [ 5773] OBJ_roleOccupant */
    0x55,0x04,0x22,                                /* [ 5776] OBJ_seeAlso */
    0x55,0x04,0x23,                                /* [ 5779] OBJ_userPassword */
    0x55,0x04,0x24,                                /* [ 5782] OBJ_userCertificate */
    0x55,0x04,0x25,                                /* [ 5785] OBJ_cACertificate */
    0x55,0x04,0x26,                                /* [ 5788] OBJ_authorityRevocationList */
    0x55,0x04,0x27,                                /* [ 5791] OBJ_certificateRevocationList */
    0x55,0x04,0x28,                                /* [ 5794] OBJ_crossCertificatePair */
    0x55,0x04,0x2F,                                /* [ 5797] OBJ_enhancedSearchGuide */
    0x55,0x04,0x30,                                /* [ 5800] OBJ_protocolInformation */
    0x55,0x04,0x31,                                /* [ 5803] OBJ_distinguishedName */
    0x55,0x04,0x32,                                /* [ 5806] OBJ_uniqueMember */
    0x55,0x04,0x33,                                /* [ 5809] OBJ_houseIdentifier */
    0x55,0x04,0x34,                                /* [ 5812] OBJ_supportedAlgorithms */
    0x55,0x04,0x35,                                /* [ 5815] OBJ_deltaRevocationList */
    0x55,0x04,0x36,                                /* [ 5818] OBJ_dmdName */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x03,0x09,  /* [ 5821] OBJ_id_alg_PWRI_KEK */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x06,  /* [ 5832] OBJ_aes_128_gcm */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x07,  /* [ 5841] OBJ_aes_128_ccm */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x08,  /* [ 5850] OBJ_id_aes128_wrap_pad */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x1A,  /* [ 5859] OBJ_aes_192_gcm */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x1B,  /* [ 5868] OBJ_aes_192_ccm */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x1C,  /* [ 5877] OBJ_id_aes192_wrap_pad */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x2E,  /* [ 5886] OBJ_aes_256_gcm */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x2F,  /* [ 5895] OBJ_aes_256_ccm */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x01,0x30,  /* [ 5904] OBJ_id_aes256_wrap_pad */
    0x2A,0x83,0x08,0x8C,0x9A,0x4B,0x3D,0x01,0x01,0x03,0x02,  /* [ 5913] OBJ_id_camellia128_wrap */
    0x2A,0x83,0x08,0x8C,0x9A,0x4B,0x3D,0x01,0x01,0x03,0x03,  /* [ 5924] OBJ_id_camellia192_wrap */
    0x2A,0x83,0x08,0x8C,0x9A,0x4B,0x3D,0x01,0x01,0x03,0x04,  /* [ 5935] OBJ_id_camellia256_wrap */
    0x55,0x1D,0x25,0x00,                           /* [ 5946] OBJ_anyExtendedKeyUsage */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x08,  /* [ 5950] OBJ_mgf1 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x0A,  /* [ 5959] OBJ_rsassaPss */
    0x2B,0x6F,0x02,0x8C,0x53,0x00,0x01,0x01,       /* [ 5968] OBJ_aes_128_xts */
    0x2B,0x6F,0x02,0x8C,0x53,0x00,0x01,0x02,       /* [ 5976] OBJ_aes_256_xts */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x07,  /* [ 5984] OBJ_rsaesOaep */
    0x2A,0x86,0x48,0xCE,0x3E,0x02,0x01,            /* [ 5993] OBJ_dhpublicnumber */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x01,  /* [ 6000] OBJ_brainpoolP160r1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x02,  /* [ 6009] OBJ_brainpoolP160t1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x03,  /* [ 6018] OBJ_brainpoolP192r1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x04,  /* [ 6027] OBJ_brainpoolP192t1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x05,  /* [ 6036] OBJ_brainpoolP224r1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x06,  /* [ 6045] OBJ_brainpoolP224t1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x07,  /* [ 6054] OBJ_brainpoolP256r1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x08,  /* [ 6063] OBJ_brainpoolP256t1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x09,  /* [ 6072] OBJ_brainpoolP320r1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x0A,  /* [ 6081] OBJ_brainpoolP320t1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x0B,  /* [ 6090] OBJ_brainpoolP384r1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x0C,  /* [ 6099] OBJ_brainpoolP384t1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x0D,  /* [ 6108] OBJ_brainpoolP512r1 */
    0x2B,0x24,0x03,0x03,0x02,0x08,0x01,0x01,0x0E,  /* [ 6117] OBJ_brainpoolP512t1 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x09,  /* [ 6126] OBJ_pSpecified */
    0x2B,0x81,0x05,0x10,0x86,0x48,0x3F,0x00,0x02,  /* [ 6135] OBJ_dhSinglePass_stdDH_sha1kdf_scheme */
    0x2B,0x81,0x04,0x01,0x0B,0x00,                 /* [ 6144] OBJ_dhSinglePass_stdDH_sha224kdf_scheme */
    0x2B,0x81,0x04,0x01,0x0B,0x01,                 /* [ 6150] OBJ_dhSinglePass_stdDH_sha256kdf_scheme */
    0x2B,0x81,0x04,0x01,0x0B,0x02,                 /* [ 6156] OBJ_dhSinglePass_stdDH_sha384kdf_scheme */
    0x2B,0x81,0x04,0x01,0x0B,0x03,                 /* [ 6162] OBJ_dhSinglePass_stdDH_sha512kdf_scheme */
    0x2B,0x81,0x05,0x10,0x86,0x48,0x3F,0x00,0x03,  /* [ 6168] OBJ_dhSinglePass_cofactorDH_sha1kdf_scheme */
    0x2B,0x81,0x04,0x01,0x0E,0x00,                 /* [ 6177] OBJ_dhSinglePass_cofactorDH_sha224kdf_scheme */
    0x2B,0x81,0x04,0x01,0x0E,0x01,                 /* [ 6183] OBJ_dhSinglePass_cofactorDH_sha256kdf_scheme */
    0x2B,0x81,0x04,0x01,0x0E,0x02,                 /* [ 6189] OBJ_dhSinglePass_cofactorDH_sha384kdf_scheme */
    0x2B,0x81,0x04,0x01,0x0E,0x03,                 /* [ 6195] OBJ_dhSinglePass_cofactorDH_sha512kdf_scheme */
    0x2B,0x06,0x01,0x04,0x01,0xD6,0x79,0x02,0x04,0x02,  /* [ 6201] OBJ_ct_precert_scts */
    0x2B,0x06,0x01,0x04,0x01,0xD6,0x79,0x02,0x04,0x03,  /* [ 6211] OBJ_ct_precert_poison */
    0x2B,0x06,0x01,0x04,0x01,0xD6,0x79,0x02,0x04,0x04,  /* [ 6221] OBJ_ct_precert_signer */
    0x2B,0x06,0x01,0x04,0x01,0xD6,0x79,0x02,0x04,0x05,  /* [ 6231] OBJ_ct_cert_scts */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x3C,0x02,0x01,0x01,  /* [ 6241] OBJ_jurisdictionLocalityName */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x3C,0x02,0x01,0x02,  /* [ 6252] OBJ_jurisdictionStateOrProvinceName */
    0x2B,0x06,0x01,0x04,0x01,0x82,0x37,0x3C,0x02,0x01,0x03,  /* [ 6263] OBJ_jurisdictionCountryName */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x06,       /* [ 6274] OBJ_camellia_128_gcm */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x07,       /* [ 6282] OBJ_camellia_128_ccm */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x09,       /* [ 6290] OBJ_camellia_128_ctr */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x0A,       /* [ 6298] OBJ_camellia_128_cmac */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x1A,       /* [ 6306] OBJ_camellia_192_gcm */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x1B,       /* [ 6314] OBJ_camellia_192_ccm */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x1D,       /* [ 6322] OBJ_camellia_192_ctr */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x1E,       /* [ 6330] OBJ_camellia_192_cmac */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x2E,       /* [ 6338] OBJ_camellia_256_gcm */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x2F,       /* [ 6346] OBJ_camellia_256_ccm */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x31,       /* [ 6354] OBJ_camellia_256_ctr */
    0x03,0xA2,0x31,0x05,0x03,0x01,0x09,0x32,       /* [ 6362] OBJ_camellia_256_cmac */
    0x2B,0x06,0x01,0x04,0x01,0xDA,0x47,0x04,0x0B,  /* [ 6370] OBJ_id_scrypt */
    0x2A,0x85,0x03,0x07,0x01,                      /* [ 6379] OBJ_id_tc26 */
    0x2A,0x85,0x03,0x07,0x01,0x01,                 /* [ 6384] OBJ_id_tc26_algorithms */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x01,            /* [ 6390] OBJ_id_tc26_sign */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x01,0x01,       /* [ 6397] OBJ_id_GostR3410_2012_256 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x01,0x02,       /* [ 6405] OBJ_id_GostR3410_2012_512 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x02,            /* [ 6413] OBJ_id_tc26_digest */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x02,0x02,       /* [ 6420] OBJ_id_GostR3411_2012_256 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x02,0x03,       /* [ 6428] OBJ_id_GostR3411_2012_512 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x03,            /* [ 6436] OBJ_id_tc26_signwithdigest */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x03,0x02,       /* [ 6443] OBJ_id_tc26_signwithdigest_gost3410_2012_256 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x03,0x03,       /* [ 6451] OBJ_id_tc26_signwithdigest_gost3410_2012_512 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x04,            /* [ 6459] OBJ_id_tc26_mac */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x04,0x01,       /* [ 6466] OBJ_id_tc26_hmac_gost_3411_2012_256 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x04,0x02,       /* [ 6474] OBJ_id_tc26_hmac_gost_3411_2012_512 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x05,            /* [ 6482] OBJ_id_tc26_cipher */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x06,            /* [ 6489] OBJ_id_tc26_agreement */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x06,0x01,       /* [ 6496] OBJ_id_tc26_agreement_gost_3410_2012_256 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x06,0x02,       /* [ 6504] OBJ_id_tc26_agreement_gost_3410_2012_512 */
    0x2A,0x85,0x03,0x07,0x01,0x02,                 /* [ 6512] OBJ_id_tc26_constants */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,            /* [ 6518] OBJ_id_tc26_sign_constants */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x02,       /* [ 6525] OBJ_id_tc26_gost_3410_2012_512_constants */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x02,0x00,  /* [ 6533] OBJ_id_tc26_gost_3410_2012_512_paramSetTest */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x02,0x01,  /* [ 6542] OBJ_id_tc26_gost_3410_2012_512_paramSetA */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x02,0x02,  /* [ 6551] OBJ_id_tc26_gost_3410_2012_512_paramSetB */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x02,            /* [ 6560] OBJ_id_tc26_digest_constants */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x05,            /* [ 6567] OBJ_id_tc26_cipher_constants */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x05,0x01,       /* [ 6574] OBJ_id_tc26_gost_28147_constants */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x05,0x01,0x01,  /* [ 6582] OBJ_id_tc26_gost_28147_param_Z */
    0x2A,0x85,0x03,0x03,0x81,0x03,0x01,0x01,       /* [ 6591] OBJ_INN */
    0x2A,0x85,0x03,0x64,0x01,                      /* [ 6599] OBJ_OGRN */
    0x2A,0x85,0x03,0x64,0x03,                      /* [ 6604] OBJ_SNILS */
    0x2A,0x85,0x03,0x64,0x6F,                      /* [ 6609] OBJ_subjectSignTool */
    0x2A,0x85,0x03,0x64,0x70,                      /* [ 6614] OBJ_issuerSignTool */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x01,0x18,       /* [ 6619] OBJ_tlsfeature */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x11,       /* [ 6627] OBJ_ipsec_IKE */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x12,       /* [ 6635] OBJ_capwapAC */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x13,       /* [ 6643] OBJ_capwapWTP */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x15,       /* [ 6651] OBJ_sshClient */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x16,       /* [ 6659] OBJ_sshServer */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x17,       /* [ 6667] OBJ_sendRouter */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x18,       /* [ 6675] OBJ_sendProxiedRouter */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x19,       /* [ 6683] OBJ_sendOwner */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x1A,       /* [ 6691] OBJ_sendProxiedOwner */
    0x2B,0x06,0x01,0x05,0x02,0x03,                 /* [ 6699] OBJ_id_pkinit */
    0x2B,0x06,0x01,0x05,0x02,0x03,0x04,            /* [ 6705] OBJ_pkInitClientAuth */
    0x2B,0x06,0x01,0x05,0x02,0x03,0x05,            /* [ 6712] OBJ_pkInitKDC */
    0x2B,0x65,0x6E,                                /* [ 6719] OBJ_X25519 */
    0x2B,0x65,0x6F,                                /* [ 6722] OBJ_X448 */
    0x2B,0x06,0x01,0x04,0x01,0x8D,0x3A,0x0C,0x02,0x01,0x10,  /* [ 6725] OBJ_blake2b512 */
    0x2B,0x06,0x01,0x04,0x01,0x8D,0x3A,0x0C,0x02,0x02,0x08,  /* [ 6736] OBJ_blake2s256 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x13,  /* [ 6747] OBJ_id_smime_ct_contentCollection */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x17,  /* [ 6758] OBJ_id_smime_ct_authEnvelopedData */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x01,0x1C,  /* [ 6769] OBJ_id_ct_xml */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x01,  /* [ 6780] OBJ_aria_128_ecb */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x02,  /* [ 6789] OBJ_aria_128_cbc */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x03,  /* [ 6798] OBJ_aria_128_cfb128 */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x04,  /* [ 6807] OBJ_aria_128_ofb128 */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x05,  /* [ 6816] OBJ_aria_128_ctr */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x06,  /* [ 6825] OBJ_aria_192_ecb */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x07,  /* [ 6834] OBJ_aria_192_cbc */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x08,  /* [ 6843] OBJ_aria_192_cfb128 */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x09,  /* [ 6852] OBJ_aria_192_ofb128 */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x0A,  /* [ 6861] OBJ_aria_192_ctr */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x0B,  /* [ 6870] OBJ_aria_256_ecb */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x0C,  /* [ 6879] OBJ_aria_256_cbc */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x0D,  /* [ 6888] OBJ_aria_256_cfb128 */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x0E,  /* [ 6897] OBJ_aria_256_ofb128 */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x0F,  /* [ 6906] OBJ_aria_256_ctr */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x2F,  /* [ 6915] OBJ_id_smime_aa_signingCertificateV2 */
    0x2B,0x65,0x70,                                /* [ 6926] OBJ_ED25519 */
    0x2B,0x65,0x71,                                /* [ 6929] OBJ_ED448 */
    0x55,0x04,0x61,                                /* [ 6932] OBJ_organizationIdentifier */
    0x55,0x04,0x62,                                /* [ 6935] OBJ_countryCode3c */
    0x55,0x04,0x63,                                /* [ 6938] OBJ_countryCode3n */
    0x55,0x04,0x64,                                /* [ 6941] OBJ_dnsName */
    0x2B,0x24,0x08,0x03,0x03,                      /* [ 6944] OBJ_x509ExtAdmission */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x05,  /* [ 6949] OBJ_sha512_224 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x06,  /* [ 6958] OBJ_sha512_256 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x07,  /* [ 6967] OBJ_sha3_224 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x08,  /* [ 6976] OBJ_sha3_256 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x09,  /* [ 6985] OBJ_sha3_384 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x0A,  /* [ 6994] OBJ_sha3_512 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x0B,  /* [ 7003] OBJ_shake128 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x0C,  /* [ 7012] OBJ_shake256 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x0D,  /* [ 7021] OBJ_hmac_sha3_224 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x0E,  /* [ 7030] OBJ_hmac_sha3_256 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x0F,  /* [ 7039] OBJ_hmac_sha3_384 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x10,  /* [ 7048] OBJ_hmac_sha3_512 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x03,  /* [ 7057] OBJ_dsa_with_SHA384 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x04,  /* [ 7066] OBJ_dsa_with_SHA512 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x05,  /* [ 7075] OBJ_dsa_with_SHA3_224 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x06,  /* [ 7084] OBJ_dsa_with_SHA3_256 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x07,  /* [ 7093] OBJ_dsa_with_SHA3_384 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x08,  /* [ 7102] OBJ_dsa_with_SHA3_512 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x09,  /* [ 7111] OBJ_ecdsa_with_SHA3_224 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x0A,  /* [ 7120] OBJ_ecdsa_with_SHA3_256 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x0B,  /* [ 7129] OBJ_ecdsa_with_SHA3_384 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x0C,  /* [ 7138] OBJ_ecdsa_with_SHA3_512 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x0D,  /* [ 7147] OBJ_RSA_SHA3_224 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x0E,  /* [ 7156] OBJ_RSA_SHA3_256 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x0F,  /* [ 7165] OBJ_RSA_SHA3_384 */
    0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x03,0x10,  /* [ 7174] OBJ_RSA_SHA3_512 */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x25,  /* [ 7183] OBJ_aria_128_ccm */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x26,  /* [ 7192] OBJ_aria_192_ccm */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x27,  /* [ 7201] OBJ_aria_256_ccm */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x22,  /* [ 7210] OBJ_aria_128_gcm */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x23,  /* [ 7219] OBJ_aria_192_gcm */
    0x2A,0x83,0x1A,0x8C,0x9A,0x6E,0x01,0x01,0x24,  /* [ 7228] OBJ_aria_256_gcm */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x1B,       /* [ 7237] OBJ_cmcCA */
    0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x1C,       /* [ 7245] OBJ_cmcRA */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x68,0x01,       /* [ 7253] OBJ_sm4_ecb */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x68,0x02,       /* [ 7261] OBJ_sm4_cbc */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x68,0x03,       /* [ 7269] OBJ_sm4_ofb128 */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x68,0x05,       /* [ 7277] OBJ_sm4_cfb1 */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x68,0x04,       /* [ 7285] OBJ_sm4_cfb128 */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x68,0x06,       /* [ 7293] OBJ_sm4_cfb8 */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x68,0x07,       /* [ 7301] OBJ_sm4_ctr */
    0x2A,0x81,0x1C,                                /* [ 7309] OBJ_ISO_CN */
    0x2A,0x81,0x1C,0xCF,0x55,                      /* [ 7312] OBJ_oscca */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,                 /* [ 7317] OBJ_sm_scheme */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x83,0x11,       /* [ 7323] OBJ_sm3 */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x83,0x78,       /* [ 7331] OBJ_sm3WithRSAEncryption */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x0F,  /* [ 7339] OBJ_sha512_224WithRSAEncryption */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x10,  /* [ 7348] OBJ_sha512_256WithRSAEncryption */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x01,       /* [ 7357] OBJ_id_tc26_gost_3410_2012_256_constants */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x01,0x01,  /* [ 7365] OBJ_id_tc26_gost_3410_2012_256_paramSetA */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x02,0x03,  /* [ 7374] OBJ_id_tc26_gost_3410_2012_512_paramSetC */
    0x2A,0x86,0x24,                                /* [ 7383] OBJ_ISO_UA */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,            /* [ 7386] OBJ_ua_pki */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x01,0x01,  /* [ 7393] OBJ_dstu28147 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x01,0x01,0x02,  /* [ 7403] OBJ_dstu28147_ofb */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x01,0x01,0x03,  /* [ 7414] OBJ_dstu28147_cfb */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x01,0x01,0x05,  /* [ 7425] OBJ_dstu28147_wrap */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x01,0x02,  /* [ 7436] OBJ_hmacWithDstu34311 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x02,0x01,  /* [ 7446] OBJ_dstu34311 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,  /* [ 7456] OBJ_dstu4145le */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x01,0x01,  /* [ 7467] OBJ_dstu4145be */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x00,  /* [ 7480] OBJ_uacurve0 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x01,  /* [ 7493] OBJ_uacurve1 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x02,  /* [ 7506] OBJ_uacurve2 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x03,  /* [ 7519] OBJ_uacurve3 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x04,  /* [ 7532] OBJ_uacurve4 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x05,  /* [ 7545] OBJ_uacurve5 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x06,  /* [ 7558] OBJ_uacurve6 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x07,  /* [ 7571] OBJ_uacurve7 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x08,  /* [ 7584] OBJ_uacurve8 */
    0x2A,0x86,0x24,0x02,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x09,  /* [ 7597] OBJ_uacurve9 */
    0x2B,0x6F,                                     /* [ 7610] OBJ_ieee */
    0x2B,0x6F,0x02,0x8C,0x53,                      /* [ 7612] OBJ_ieee_siswg */
    0x2A,0x81,0x1C,0xCF,0x55,0x01,0x82,0x2D,       /* [ 7617] OBJ_sm2 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x05,0x01,       /* [ 7625] OBJ_id_tc26_cipher_gostr3412_2015_magma */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x05,0x01,0x01,  /* [ 7633] OBJ_id_tc26_cipher_gostr3412_2015_magma_ctracpkm */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x05,0x01,0x02,  /* [ 7642] OBJ_id_tc26_cipher_gostr3412_2015_magma_ctracpkm_omac */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x05,0x02,       /* [ 7651] OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x05,0x02,0x01,  /* [ 7659] OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x05,0x02,0x02,  /* [ 7668] OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm_omac */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x07,            /* [ 7677] OBJ_id_tc26_wrap */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x07,0x01,       /* [ 7684] OBJ_id_tc26_wrap_gostr3412_2015_magma */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x07,0x01,0x01,  /* [ 7692] OBJ_id_tc26_wrap_gostr3412_2015_magma_kexp15 */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x07,0x02,       /* [ 7701] OBJ_id_tc26_wrap_gostr3412_2015_kuznyechik */
    0x2A,0x85,0x03,0x07,0x01,0x01,0x07,0x02,0x01,  /* [ 7709] OBJ_id_tc26_wrap_gostr3412_2015_kuznyechik_kexp15 */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x01,0x02,  /* [ 7718] OBJ_id_tc26_gost_3410_2012_256_paramSetB */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x01,0x03,  /* [ 7727] OBJ_id_tc26_gost_3410_2012_256_paramSetC */
    0x2A,0x85,0x03,0x07,0x01,0x02,0x01,0x01,0x04,  /* [ 7736] OBJ_id_tc26_gost_3410_2012_256_paramSetD */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x0C,       /* [ 7745] OBJ_hmacWithSHA512_224 */
    0x2A,0x86,0x48,0x86,0xF7,0x0D,0x02,0x0D,       /* [ 7753] OBJ_hmacWithSHA512_256 */
};

#define NUM_NID 188

static const ASN1_OBJECT nid_objs[NUM_NID] = {
    {"UNDEF", "undefined", NID_undef},
    {"rsadsi", "RSA Data Security, Inc.", NID_rsadsi, 6, &so[0]},
    {"pkcs", "RSA Data Security, Inc. PKCS", NID_pkcs, 7, &so[6]},
    {"MD2", "md2", NID_md2, 8, &so[13]},
    {"MD5", "md5", NID_md5, 8, &so[21]},
    {"RC4", "rc4", NID_rc4, 8, &so[29]},
    {"rsaEncryption", "rsaEncryption", NID_rsaEncryption, 9, &so[37]},
    {"RSA-MD2", "md2WithRSAEncryption", NID_md2WithRSAEncryption, 9, &so[46]},
    {"RSA-MD5", "md5WithRSAEncryption", NID_md5WithRSAEncryption, 9, &so[55]},
    {"PBE-MD2-DES", "pbeWithMD2AndDES-CBC", NID_pbeWithMD2AndDES_CBC, 9, &so[64]},
    {"PBE-MD5-DES", "pbeWithMD5AndDES-CBC", NID_pbeWithMD5AndDES_CBC, 9, &so[73]},
    {"X500", "directory services (X.500)", NID_X500, 1, &so[82]},
    {"X509", "X509", NID_X509, 2, &so[83]},
    {"CN", "commonName", NID_commonName, 3, &so[85]},
    {"C", "countryName", NID_countryName, 3, &so[88]},
    {"L", "localityName", NID_localityName, 3, &so[91]},
    {"ST", "stateOrProvinceName", NID_stateOrProvinceName, 3, &so[94]},
    {"O", "organizationName", NID_organizationName, 3, &so[97]},
    {"OU", "organizationalUnitName", NID_organizationalUnitName, 3, &so[100]},
    {"RSA", "rsa", NID_rsa, 4, &so[103]},
    {"pkcs7", "pkcs7", NID_pkcs7, 8, &so[107]},
    {"pkcs7-data", "pkcs7-data", NID_pkcs7_data, 9, &so[115]},
    {"pkcs7-signedData", "pkcs7-signedData", NID_pkcs7_signed, 9, &so[124]},
    {"pkcs7-envelopedData", "pkcs7-envelopedData", NID_pkcs7_enveloped, 9, &so[133]},
    {"pkcs7-signedAndEnvelopedData", "pkcs7-signedAndEnvelopedData", NID_pkcs7_signedAndEnveloped, 9, &so[142]},
    {"pkcs7-digestData", "pkcs7-digestData", NID_pkcs7_digest, 9, &so[151]},
    {"pkcs7-encryptedData", "pkcs7-encryptedData", NID_pkcs7_encrypted, 9, &so[160]},
    {"pkcs3", "pkcs3", NID_pkcs3, 8, &so[169]},
    {"dhKeyAgreement", "dhKeyAgreement", NID_dhKeyAgreement, 9, &so[177]},
    {"DES-ECB", "des-ecb", NID_des_ecb, 5, &so[186]},
    {"DES-CFB", "des-cfb", NID_des_cfb64, 5, &so[191]},
    {"DES-CBC", "des-cbc", NID_des_cbc, 5, &so[196]},
    {"DES-EDE", "des-ede", NID_des_ede_ecb, 5, &so[201]},
    {"DES-EDE3", "des-ede3", NID_des_ede3_ecb},
    {"IDEA-CBC", "idea-cbc", NID_idea_cbc, 11, &so[206]},
    {"IDEA-CFB", "idea-cfb", NID_idea_cfb64},
    {"IDEA-ECB", "idea-ecb", NID_idea_ecb},
    {"RC2-CBC", "rc2-cbc", NID_rc2_cbc, 8, &so[217]},
    {"RC2-ECB", "rc2-ecb", NID_rc2_ecb},
    {"RC2-CFB", "rc2-cfb", NID_rc2_cfb64},
    {"RC2-OFB", "rc2-ofb", NID_rc2_ofb64},
    {"SHA", "sha", NID_sha, 5, &so[225]},
    {"RSA-SHA", "shaWithRSAEncryption", NID_shaWithRSAEncryption, 5, &so[230]},
    {"DES-EDE-CBC", "des-ede-cbc", NID_des_ede_cbc},
    {"DES-EDE3-CBC", "des-ede3-cbc", NID_des_ede3_cbc, 8, &so[235]},
    {"DES-OFB", "des-ofb", NID_des_ofb64, 5, &so[243]},
    {"IDEA-OFB", "idea-ofb", NID_idea_ofb64},
    {"pkcs9", "pkcs9", NID_pkcs9, 8, &so[248]},
    {"emailAddress", "emailAddress", NID_pkcs9_emailAddress, 9, &so[256]},
    {"unstructuredName", "unstructuredName", NID_pkcs9_unstructuredName, 9, &so[265]},
    {"contentType", "contentType", NID_pkcs9_contentType, 9, &so[274]},
    {"messageDigest", "messageDigest", NID_pkcs9_messageDigest, 9, &so[283]},
    {"signingTime", "signingTime", NID_pkcs9_signingTime, 9, &so[292]},
    {"countersignature", "countersignature", NID_pkcs9_countersignature, 9, &so[301]},
    {"challengePassword", "challengePassword", NID_pkcs9_challengePassword, 9, &so[310]},
    {"unstructuredAddress", "unstructuredAddress", NID_pkcs9_unstructuredAddress, 9, &so[319]},
    {"extendedCertificateAttributes", "extendedCertificateAttributes", NID_pkcs9_extCertAttributes, 9, &so[328]},
    {"Netscape", "Netscape Communications Corp.", NID_netscape, 7, &so[337]},
    {"nsCertExt", "Netscape Certificate Extension", NID_netscape_cert_extension, 8, &so[344]},
    {"nsDataType", "Netscape Data Type", NID_netscape_data_type, 8, &so[352]},
    {"DES-EDE-CFB", "des-ede-cfb", NID_des_ede_cfb64},
    {"DES-EDE3-CFB", "des-ede3-cfb", NID_des_ede3_cfb64},
    {"DES-EDE-OFB", "des-ede-ofb", NID_des_ede_ofb64},
    {"DES-EDE3-OFB", "des-ede3-ofb", NID_des_ede3_ofb64},
    {"SHA1", "sha1", NID_sha1, 5, &so[360]},
    {"RSA-SHA1", "sha1WithRSAEncryption", NID_sha1WithRSAEncryption, 9, &so[365]},
    {"DSA-SHA", "dsaWithSHA", NID_dsaWithSHA, 5, &so[374]},
    {"DSA-old", "dsaEncryption-old", NID_dsa_2, 5, &so[379]},
    {"PBE-SHA1-RC2-64", "pbeWithSHA1AndRC2-CBC", NID_pbeWithSHA1AndRC2_CBC, 9, &so[384]},
    {"PBKDF2", "PBKDF2", NID_id_pbkdf2, 9, &so[393]},
    {"DSA-SHA1-old", "dsaWithSHA1-old", NID_dsaWithSHA1_2, 5, &so[402]},
    {"nsCertType", "Netscape Cert Type", NID_netscape_cert_type, 9, &so[407]},
    {"nsBaseUrl", "Netscape Base Url", NID_netscape_base_url, 9, &so[416]},
    {"nsRevocationUrl", "Netscape Revocation Url", NID_netscape_revocation_url, 9, &so[425]},
    {"nsCaRevocationUrl", "Netscape CA Revocation Url", NID_netscape_ca_revocation_url, 9, &so[434]},
    {"nsRenewalUrl", "Netscape Renewal Url", NID_netscape_renewal_url, 9, &so[443]},
    {"nsCaPolicyUrl", "Netscape CA Policy Url", NID_netscape_ca_policy_url, 9, &so[452]},
    {"nsSslServerName", "Netscape SSL Server Name", NID_netscape_ssl_server_name, 9, &so[461]},
    {"nsComment", "Netscape Comment", NID_netscape_comment, 9, &so[470]},
    {"nsCertSequence", "Netscape Certificate Sequence", NID_netscape_cert_sequence, 9, &so[479]},
    {"DESX-CBC", "desx-cbc", NID_desx_cbc},
    {"id-ce", "id-ce", NID_id_ce, 2, &so[488]},
    {"subjectKeyIdentifier", "X509v3 Subject Key Identifier", NID_subject_key_identifier, 3, &so[490]},
    {"keyUsage", "X509v3 Key Usage", NID_key_usage, 3, &so[493]},
    {"privateKeyUsagePeriod", "X509v3 Private Key Usage Period", NID_private_key_usage_period, 3, &so[496]},
    {"subjectAltName", "X509v3 Subject Alternative Name", NID_subject_alt_name, 3, &so[499]},
    {"issuerAltName", "X509v3 Issuer Alternative Name", NID_issuer_alt_name, 3, &so[502]},
    {"basicConstraints", "X509v3 Basic Constraints", NID_basic_constraints, 3, &so[505]},
    {"crlNumber", "X509v3 CRL Number", NID_crl_number, 3, &so[508]},
    {"certificatePolicies", "X509v3 Certificate Policies", NID_certificate_policies, 3, &so[511]},
    {"authorityKeyIdentifier", "X509v3 Authority Key Identifier", NID_authority_key_identifier, 3, &so[514]},
    {"BF-CBC", "bf-cbc", NID_bf_cbc, 9, &so[517]},
    {"BF-ECB", "bf-ecb", NID_bf_ecb},
    {"BF-CFB", "bf-cfb", NID_bf_cfb64},
    {"BF-OFB", "bf-ofb", NID_bf_ofb64},
    {"MDC2", "mdc2", NID_mdc2, 4, &so[526]},
    {"RSA-MDC2", "mdc2WithRSA", NID_mdc2WithRSA, 4, &so[530]},
    {"RC4-40", "rc4-40", NID_rc4_40},
    {"RC2-40-CBC", "rc2-40-cbc", NID_rc2_40_cbc},
    {"GN", "givenName", NID_givenName, 3, &so[534]},
    {"SN", "surname", NID_surname, 3, &so[537]},
    {"initials", "initials", NID_initials, 3, &so[540]},
    {"uid", "uniqueIdentifier", NID_uniqueIdentifier, 10, &so[543]},
    {"crlDistributionPoints", "X509v3 CRL Distribution Points", NID_crl_distribution_points, 3, &so[553]},
    {"RSA-NP-MD5", "md5WithRSA", NID_md5WithRSA, 5, &so[556]},
    {"serialNumber", "serialNumber", NID_serialNumber, 3, &so[561]},
    {"title", "title", NID_title, 3, &so[564]},
    {"description", "description", NID_description, 3, &so[567]},
    {"CAST5-CBC", "cast5-cbc", NID_cast5_cbc, 9, &so[570]},
    {"CAST5-ECB", "cast5-ecb", NID_cast5_ecb},
    {"CAST5-CFB", "cast5-cfb", NID_cast5_cfb64},
    {"CAST5-OFB", "cast5-ofb", NID_cast5_ofb64},
    {"pbeWithMD5AndCast5CBC", "pbeWithMD5AndCast5CBC", NID_pbeWithMD5AndCast5_CBC, 9, &so[579]},
    {"DSA-SHA1", "dsaWithSHA1", NID_dsaWithSHA1, 7, &so[588]},
    {"MD5-SHA1", "md5-sha1", NID_md5_sha1},
    {"RSA-SHA1-2", "sha1WithRSA", NID_sha1WithRSA, 5, &so[595]},
    {"DSA", "dsaEncryption", NID_dsa, 7, &so[600]},
    {"RIPEMD160", "ripemd160", NID_ripemd160, 5, &so[607]},
    {"RSA-RIPEMD160", "ripemd160WithRSA", NID_ripemd160WithRSA, 6, &so[612]},
    {"RC5-CBC", "rc5-cbc", NID_rc5_cbc, 8, &so[618]},
    {"RC5-ECB", "rc5-ecb", NID_rc5_ecb},
    {"RC5-CFB", "rc5-cfb", NID_rc5_cfb64},
    {"RC5-OFB", "rc5-ofb", NID_rc5_ofb64},
    {"ZLIB", "zlib compression", NID_zlib_compression, 11, &so[626]},
    {"extendedKeyUsage", "X509v3 Extended Key Usage", NID_ext_key_usage, 3, &so[637]},
    {"PKIX", "PKIX", NID_id_pkix, 6, &so[640]},
    {"id-kp", "id-kp", NID_id_kp, 7, &so[646]},
    {"serverAuth", "TLS Web Server Authentication", NID_server_auth, 8, &so[653]},
    {"clientAuth", "TLS Web Client Authentication", NID_client_auth, 8, &so[661]},
    {"codeSigning", "Code Signing", NID_code_sign, 8, &so[669]},
    {"emailProtection", "E-mail Protection", NID_email_protect, 8, &so[677]},
    {"timeStamping", "Time Stamping", NID_time_stamp, 8, &so[685]},
    {"msCodeInd", "Microsoft Individual Code Signing", NID_ms_code_ind, 10, &so[693]},
    {"msCodeCom", "Microsoft Commercial Code Signing", NID_ms_code_com, 10, &so[703]},
    {"msCTLSign", "Microsoft Trust List Signing", NID_ms_ctl_sign, 10, &so[713]},
    {"msSGC", "Microsoft Server Gated Crypto", NID_ms_sgc, 10, &so[723]},
    {"msEFS", "Microsoft Encrypted File System", NID_ms_efs, 10, &so[733]},
    {"nsSGC", "Netscape Server Gated Crypto", NID_ns_sgc, 9, &so[743]},
    {"deltaCRL", "X509v3 Delta CRL Indicator", NID_delta_crl, 3, &so[752]},
    {"CRLReason", "X509v3 CRL Reason Code", NID_crl_reason, 3, &so[755]},
    {"invalidityDate", "Invalidity Date", NID_invalidity_date, 3, &so[758]},
    {"SXNetID", "Strong Extranet ID", NID_sxnet, 5, &so[761]},
    {"PBE-SHA1-RC4-128", "pbeWithSHA1And128BitRC4", NID_pbe_WithSHA1And128BitRC4, 10, &so[766]},
    {"PBE-SHA1-RC4-40", "pbeWithSHA1And40BitRC4", NID_pbe_WithSHA1And40BitRC4, 10, &so[776]},
    {"PBE-SHA1-3DES", "pbeWithSHA1And3-KeyTripleDES-CBC", NID_pbe_WithSHA1And3_Key_TripleDES_CBC, 10, &so[786]},
    {"PBE-SHA1-2DES", "pbeWithSHA1And2-KeyTripleDES-CBC", NID_pbe_WithSHA1And2_Key_TripleDES_CBC, 10, &so[796]},
    {"PBE-SHA1-RC2-128", "pbeWithSHA1And128BitRC2-CBC", NID_pbe_WithSHA1And128BitRC2_CBC, 10, &so[806]},
    {"PBE-SHA1-RC2-40", "pbeWithSHA1And40BitRC2-CBC", NID_pbe_WithSHA1And40BitRC2_CBC, 10, &so[816]},
    {"keyBag", "keyBag", NID_keyBag, 11, &so[826]},
    {"pkcs8ShroudedKeyBag", "pkcs8ShroudedKeyBag", NID_pkcs8ShroudedKeyBag, 11, &so[837]},
    {"certBag", "certBag", NID_certBag, 11, &so[848]},
    {"crlBag", "crlBag", NID_crlBag, 11, &so[859]},
    {"secretBag", "secretBag", NID_secretBag, 11, &so[870]},
    {"safeContentsBag", "safeContentsBag", NID_safeContentsBag, 11, &so[881]},
    {"friendlyName", "friendlyName", NID_friendlyName, 9, &so[892]},
    {"localKeyID", "localKeyID", NID_localKeyID, 9, &so[901]},
    {"x509Certificate", "x509Certificate", NID_x509Certificate, 10, &so[910]},
    {"sdsiCertificate", "sdsiCertificate", NID_sdsiCertificate, 10, &so[920]},
    {"x509Crl", "x509Crl", NID_x509Crl, 10, &so[930]},
    {"PBES2", "PBES2", NID_pbes2, 9, &so[940]},
    {"PBMAC1", "PBMAC1", NID_pbmac1, 9, &so[949]},
    {"hmacWithSHA1", "hmacWithSHA1", NID_hmacWithSHA1, 8, &so[958]},
    {"id-qt-cps", "Policy Qualifier CPS", NID_id_qt_cps, 8, &so[966]},
    {"id-qt-unotice", "Policy Qualifier User Notice", NID_id_qt_unotice, 8, &so[974]},
    {"RC2-64-CBC", "rc2-64-cbc", NID_rc2_64_cbc},
    {"SMIME-CAPS", "S/MIME Capabilities", NID_SMIMECapabilities, 9, &so[982]},
    {"PBE-MD2-RC2-64", "pbeWithMD2AndRC2-CBC", NID_pbeWithMD2AndRC2_CBC, 9, &so[991]},
    {"PBE-MD5-RC2-64", "pbeWithMD5AndRC2-CBC", NID_pbeWithMD5AndRC2_CBC, 9, &so[1000]},
    {"PBE-SHA1-DES", "pbeWithSHA1AndDES-CBC", NID_pbeWithSHA1AndDES_CBC, 9, &so[1009]},
    {"msExtReq", "Microsoft Extension Request", NID_ms_ext_req, 10, &so[1018]},
    {"extReq", "Extension Request", NID_ext_req, 9, &so[1028]},
    {"name", "name", NID_name, 3, &so[1037]},
    {"dnQualifier", "dnQualifier", NID_dnQualifier, 3, &so[1040]},
    {"id-pe", "id-pe", NID_id_pe, 7, &so[1043]},
    {"id-ad", "id-ad", NID_id_ad, 7, &so[1050]},
    {"authorityInfoAccess", "Authority Information Access", NID_info_access, 8, &so[1057]},
    {"OCSP", "OCSP", NID_ad_OCSP, 8, &so[1065]},
    {"caIssuers", "CA Issuers", NID_ad_ca_issuers, 8, &so[1073]},
    {"OCSPSigning", "OCSP Signing", NID_OCSP_sign, 8, &so[1081]},
    {"ISO", "iso", NID_iso},
    {"member-body", "ISO Member Body", NID_member_body, 1, &so[1089]},
    {"ISO-US", "ISO US Member Body", NID_ISO_US, 3, &so[1090]},
    {"X9-57", "X9.57", NID_X9_57, 5, &so[1093]},
    {"X9cm", "X9.57 CM ?", NID_X9cm, 6, &so[1098]},
    {"pkcs1", "pkcs1", NID_pkcs1, 8, &so[1104]},
    {"pkcs5", "pkcs5", NID_pkcs5, 8, &so[1112]},
};

#define NUM_SN 1186
static const unsigned int sn_objs[NUM_SN] = {
     364,    /* "AD_DVCS" */
     419,    /* "AES-128-CBC" */
     916,    /* "AES-128-CBC-HMAC-SHA1" */
     948,    /* "AES-128-CBC-HMAC-SHA256" */
     421,    /* "AES-128-CFB" */
     650,    /* "AES-128-CFB1" */
     653,    /* "AES-128-CFB8" */
     904,    /* "AES-128-CTR" */
     418,    /* "AES-128-ECB" */
     958,    /* "AES-128-OCB" */
     420,    /* "AES-128-OFB" */
     913,    /* "AES-128-XTS" */
     423,    /* "AES-192-CBC" */
     917,    /* "AES-192-CBC-HMAC-SHA1" */
     949,    /* "AES-192-CBC-HMAC-SHA256" */
     425,    /* "AES-192-CFB" */
     651,    /* "AES-192-CFB1" */
     654,    /* "AES-192-CFB8" */
     905,    /* "AES-192-CTR" */
     422,    /* "AES-192-ECB" */
     959,    /* "AES-192-OCB" */
     424,    /* "AES-192-OFB" */
     427,    /* "AES-256-CBC" */
     918,    /* "AES-256-CBC-HMAC-SHA1" */
     950,    /* "AES-256-CBC-HMAC-SHA256" */
     429,    /* "AES-256-CFB" */
     652,    /* "AES-256-CFB1" */
     655,    /* "AES-256-CFB8" */
     906,    /* "AES-256-CTR" */
     426,    /* "AES-256-ECB" */
     960,    /* "AES-256-OCB" */
     428,    /* "AES-256-OFB" */
     914,    /* "AES-256-XTS" */
    1066,    /* "ARIA-128-CBC" */
    1120,    /* "ARIA-128-CCM" */
    1067,    /* "ARIA-128-CFB" */
    1080,    /* "ARIA-128-CFB1" */
    1083,    /* "ARIA-128-CFB8" */
    1069,    /* "ARIA-128-CTR" */
    1065,    /* "ARIA-128-ECB" */
    1123,    /* "ARIA-128-GCM" */
    1068,    /* "ARIA-128-OFB" */
    1071,    /* "ARIA-192-CBC" */
    1121,    /* "ARIA-192-CCM" */
    1072,    /* "ARIA-192-CFB" */
    1081,    /* "ARIA-192-CFB1" */
    1084,    /* "ARIA-192-CFB8" */
    1074,    /* "ARIA-192-CTR" */
    1070,    /* "ARIA-192-ECB" */
    1124,    /* "ARIA-192-GCM" */
    1073,    /* "ARIA-192-OFB" */
    1076,    /* "ARIA-256-CBC" */
    1122,    /* "ARIA-256-CCM" */
    1077,    /* "ARIA-256-CFB" */
    1082,    /* "ARIA-256-CFB1" */
    1085,    /* "ARIA-256-CFB8" */
    1079,    /* "ARIA-256-CTR" */
    1075,    /* "ARIA-256-ECB" */
    1125,    /* "ARIA-256-GCM" */
    1078,    /* "ARIA-256-OFB" */
    1064,    /* "AuthANY" */
    1049,    /* "AuthDSS" */
    1047,    /* "AuthECDSA" */
    1050,    /* "AuthGOST01" */
    1051,    /* "AuthGOST12" */
    1053,    /* "AuthNULL" */
    1048,    /* "AuthPSK" */
    1046,    /* "AuthRSA" */
    1052,    /* "AuthSRP" */
      91,    /* "BF-CBC" */
      93,    /* "BF-CFB" */
      92,    /* "BF-ECB" */
      94,    /* "BF-OFB" */
    1056,    /* "BLAKE2b512" */
    1057,    /* "BLAKE2s256" */
      14,    /* "C" */
     751,    /* "CAMELLIA-128-CBC" */
     962,    /* "CAMELLIA-128-CCM" */
     757,    /* "CAMELLIA-128-CFB" */
     760,    /* "CAMELLIA-128-CFB1" */
     763,    /* "CAMELLIA-128-CFB8" */
     964,    /* "CAMELLIA-128-CMAC" */
     963,    /* "CAMELLIA-128-CTR" */
     754,    /* "CAMELLIA-128-ECB" */
     961,    /* "CAMELLIA-128-GCM" */
     766,    /* "CAMELLIA-128-OFB" */
     752,    /* "CAMELLIA-192-CBC" */
     966,    /* "CAMELLIA-192-CCM" */
     758,    /* "CAMELLIA-192-CFB" */
     761,    /* "CAMELLIA-192-CFB1" */
     764,    /* "CAMELLIA-192-CFB8" */
     968,    /* "CAMELLIA-192-CMAC" */
     967,    /* "CAMELLIA-192-CTR" */
     755,    /* "CAMELLIA-192-ECB" */
     965,    /* "CAMELLIA-192-GCM" */
     767,    /* "CAMELLIA-192-OFB" */
     753,    /* "CAMELLIA-256-CBC" */
     970,    /* "CAMELLIA-256-CCM" */
     759,    /* "CAMELLIA-256-CFB" */
     762,    /* "CAMELLIA-256-CFB1" */
     765,    /* "CAMELLIA-256-CFB8" */
     972,    /* "CAMELLIA-256-CMAC" */
     971,    /* "CAMELLIA-256-CTR" */
     756,    /* "CAMELLIA-256-ECB" */
     969,    /* "CAMELLIA-256-GCM" */
     768,    /* "CAMELLIA-256-OFB" */
     108,    /* "CAST5-CBC" */
     110,    /* "CAST5-CFB" */
     109,    /* "CAST5-ECB" */
     111,    /* "CAST5-OFB" */
     894,    /* "CMAC" */
      13,    /* "CN" */
     141,    /* "CRLReason" */
     417,    /* "CSPName" */
    1019,    /* "ChaCha20" */
    1018,    /* "ChaCha20-Poly1305" */
     367,    /* "CrlID" */
     391,    /* "DC" */
      31,    /* "DES-CBC" */
     643,    /* "DES-CDMF" */
      30,    /* "DES-CFB" */
     656,    /* "DES-CFB1" */
     657,    /* "DES-CFB8" */
      29,    /* "DES-ECB" */
      32,    /* "DES-EDE" */
      43,    /* "DES-EDE-CBC" */
      60,    /* "DES-EDE-CFB" */
      62,    /* "DES-EDE-OFB" */
      33,    /* "DES-EDE3" */
      44,    /* "DES-EDE3-CBC" */
      61,    /* "DES-EDE3-CFB" */
     658,    /* "DES-EDE3-CFB1" */
     659,    /* "DES-EDE3-CFB8" */
      63,    /* "DES-EDE3-OFB" */
      45,    /* "DES-OFB" */
      80,    /* "DESX-CBC" */
     380,    /* "DOD" */
     116,    /* "DSA" */
      66,    /* "DSA-SHA" */
     113,    /* "DSA-SHA1" */
      70,    /* "DSA-SHA1-old" */
      67,    /* "DSA-old" */
     297,    /* "DVCS" */
    1087,    /* "ED25519" */
    1088,    /* "ED448" */
      99,    /* "GN" */
    1036,    /* "HKDF" */
     855,    /* "HMAC" */
     780,    /* "HMAC-MD5" */
     781,    /* "HMAC-SHA1" */
     381,    /* "IANA" */
      34,    /* "IDEA-CBC" */
      35,    /* "IDEA-CFB" */
      36,    /* "IDEA-ECB" */
      46,    /* "IDEA-OFB" */
    1004,    /* "INN" */
     181,    /* "ISO" */
    1140,    /* "ISO-CN" */
    1150,    /* "ISO-UA" */
     183,    /* "ISO-US" */
     645,    /* "ITU-T" */
     646,    /* "JOINT-ISO-ITU-T" */
     773,    /* "KISA" */
    1063,    /* "KxANY" */
    1039,    /* "KxDHE" */
    1041,    /* "KxDHE-PSK" */
    1038,    /* "KxECDHE" */
    1040,    /* "KxECDHE-PSK" */
    1045,    /* "KxGOST" */
    1043,    /* "KxPSK" */
    1037,    /* "KxRSA" */
    1042,    /* "KxRSA_PSK" */
    1044,    /* "KxSRP" */
      15,    /* "L" */
     856,    /* "LocalKeySet" */
       3,    /* "MD2" */
     257,    /* "MD4" */
       4,    /* "MD5" */
     114,    /* "MD5-SHA1" */
      95,    /* "MDC2" */
     911,    /* "MGF1" */
     388,    /* "Mail" */
     393,    /* "NULL" */
     404,    /* "NULL" */
      57,    /* "Netscape" */
     366,    /* "Nonce" */
      17,    /* "O" */
     178,    /* "OCSP" */
     180,    /* "OCSPSigning" */
    1005,    /* "OGRN" */
     379,    /* "ORG" */
      18,    /* "OU" */
     749,    /* "Oakley-EC2N-3" */
     750,    /* "Oakley-EC2N-4" */
       9,    /* "PBE-MD2-DES" */
     168,    /* "PBE-MD2-RC2-64" */
      10,    /* "PBE-MD5-DES" */
     169,    /* "PBE-MD5-RC2-64" */
     147,    /* "PBE-SHA1-2DES" */
     146,    /* "PBE-SHA1-3DES" */
     170,    /* "PBE-SHA1-DES" */
     148,    /* "PBE-SHA1-RC2-128" */
     149,    /* "PBE-SHA1-RC2-40" */
      68,    /* "PBE-SHA1-RC2-64" */
     144,    /* "PBE-SHA1-RC4-128" */
     145,    /* "PBE-SHA1-RC4-40" */
     161,    /* "PBES2" */
      69,    /* "PBKDF2" */
     162,    /* "PBMAC1" */
     127,    /* "PKIX" */
     935,    /* "PSPECIFIED" */
    1061,    /* "Poly1305" */
      98,    /* "RC2-40-CBC" */
     166,    /* "RC2-64-CBC" */
      37,    /* "RC2-CBC" */
      39,    /* "RC2-CFB" */
      38,    /* "RC2-ECB" */
      40,    /* "RC2-OFB" */
       5,    /* "RC4" */
      97,    /* "RC4-40" */
     915,    /* "RC4-HMAC-MD5" */
     120,    /* "RC5-CBC" */
     122,    /* "RC5-CFB" */
     121,    /* "RC5-ECB" */
     123,    /* "RC5-OFB" */
     117,    /* "RIPEMD160" */
      19,    /* "RSA" */
       7,    /* "RSA-MD2" */
     396,    /* "RSA-MD4" */
       8,    /* "RSA-MD5" */
      96,    /* "RSA-MDC2" */
     104,    /* "RSA-NP-MD5" */
     119,    /* "RSA-RIPEMD160" */
      42,    /* "RSA-SHA" */
      65,    /* "RSA-SHA1" */
     115,    /* "RSA-SHA1-2" */
     671,    /* "RSA-SHA224" */
     668,    /* "RSA-SHA256" */
     669,    /* "RSA-SHA384" */
     670,    /* "RSA-SHA512" */
    1145,    /* "RSA-SHA512/224" */
    1146,    /* "RSA-SHA512/256" */
    1144,    /* "RSA-SM3" */
     919,    /* "RSAES-OAEP" */
     912,    /* "RSASSA-PSS" */
     777,    /* "SEED-CBC" */
     779,    /* "SEED-CFB" */
     776,    /* "SEED-ECB" */
     778,    /* "SEED-OFB" */
      41,    /* "SHA" */
      64,    /* "SHA1" */
     675,    /* "SHA224" */
     672,    /* "SHA256" */
    1096,    /* "SHA3-224" */
    1097,    /* "SHA3-256" */
    1098,    /* "SHA3-384" */
    1099,    /* "SHA3-512" */
     673,    /* "SHA384" */
     674,    /* "SHA512" */
    1094,    /* "SHA512-224" */
    1095,    /* "SHA512-256" */
    1100,    /* "SHAKE128" */
    1101,    /* "SHAKE256" */
    1172,    /* "SM2" */
    1143,    /* "SM3" */
    1134,    /* "SM4-CBC" */
    1137,    /* "SM4-CFB" */
    1136,    /* "SM4-CFB1" */
    1138,    /* "SM4-CFB8" */
    1139,    /* "SM4-CTR" */
    1133,    /* "SM4-ECB" */
    1135,    /* "SM4-OFB" */
     188,    /* "SMIME" */
     167,    /* "SMIME-CAPS" */
     100,    /* "SN" */
    1006,    /* "SNILS" */
      16,    /* "ST" */
     143,    /* "SXNetID" */
    1062,    /* "SipHash" */
    1021,    /* "TLS1-PRF" */
     458,    /* "UID" */
       0,    /* "UNDEF" */
    1034,    /* "X25519" */
    1035,    /* "X448" */
      11,    /* "X500" */
     378,    /* "X500algorithms" */
      12,    /* "X509" */
     184,    /* "X9-57" */
     185,    /* "X9cm" */
     125,    /* "ZLIB" */
     478,    /* "aRecord" */
     289,    /* "aaControls" */
     287,    /* "ac-auditEntity" */
     397,    /* "ac-proxying" */
     288,    /* "ac-targeting" */
     368,    /* "acceptableResponses" */
     446,    /* "account" */
     363,    /* "ad_timestamping" */
     376,    /* "algorithm" */
     405,    /* "ansi-X9-62" */
     910,    /* "anyExtendedKeyUsage" */
     746,    /* "anyPolicy" */
     370,    /* "archiveCutoff" */
     484,    /* "associatedDomain" */
     485,    /* "associatedName" */
     501,    /* "audio" */
     177,    /* "authorityInfoAccess" */
      90,    /* "authorityKeyIdentifier" */
     882,    /* "authorityRevocationList" */
      87,    /* "basicConstraints" */
     365,    /* "basicOCSPResponse" */
     285,    /* "biometricInfo" */
     921,    /* "brainpoolP160r1" */
     922,    /* "brainpoolP160t1" */
     923,    /* "brainpoolP192r1" */
     924,    /* "brainpoolP192t1" */
     925,    /* "brainpoolP224r1" */
     926,    /* "brainpoolP224t1" */
     927,    /* "brainpoolP256r1" */
     928,    /* "brainpoolP256t1" */
     929,    /* "brainpoolP320r1" */
     930,    /* "brainpoolP320t1" */
     931,    /* "brainpoolP384r1" */
     932,    /* "brainpoolP384t1" */
     933,    /* "brainpoolP512r1" */
     934,    /* "brainpoolP512t1" */
     494,    /* "buildingName" */
     860,    /* "businessCategory" */
     691,    /* "c2onb191v4" */
     692,    /* "c2onb191v5" */
     697,    /* "c2onb239v4" */
     698,    /* "c2onb239v5" */
     684,    /* "c2pnb163v1" */
     685,    /* "c2pnb163v2" */
     686,    /* "c2pnb163v3" */
     687,    /* "c2pnb176v1" */
     693,    /* "c2pnb208w1" */
     699,    /* "c2pnb272w1" */
     700,    /* "c2pnb304w1" */
     702,    /* "c2pnb368w1" */
     688,    /* "c2tnb191v1" */
     689,    /* "c2tnb191v2" */
     690,    /* "c2tnb191v3" */
     694,    /* "c2tnb239v1" */
     695,    /* "c2tnb239v2" */
     696,    /* "c2tnb239v3" */
     701,    /* "c2tnb359v1" */
     703,    /* "c2tnb431r1" */
    1090,    /* "c3" */
     881,    /* "cACertificate" */
     483,    /* "cNAMERecord" */
     179,    /* "caIssuers" */
     785,    /* "caRepository" */
    1023,    /* "capwapAC" */
    1024,    /* "capwapWTP" */
     443,    /* "caseIgnoreIA5StringSyntax" */
     152,    /* "certBag" */
     677,    /* "certicom-arc" */
     771,    /* "certificateIssuer" */
      89,    /* "certificatePolicies" */
     883,    /* "certificateRevocationList" */
      54,    /* "challengePassword" */
     407,    /* "characteristic-two-field" */
     395,    /* "clearance" */
     130,    /* "clientAuth" */
    1131,    /* "cmcCA" */
    1132,    /* "cmcRA" */
     131,    /* "codeSigning" */
      50,    /* "contentType" */
      53,    /* "countersignature" */
     153,    /* "crlBag" */
     103,    /* "crlDistributionPoints" */
      88,    /* "crlNumber" */
     884,    /* "crossCertificatePair" */
     806,    /* "cryptocom" */
     805,    /* "cryptopro" */
     954,    /* "ct_cert_scts" */
     952,    /* "ct_precert_poison" */
     951,    /* "ct_precert_scts" */
     953,    /* "ct_precert_signer" */
     500,    /* "dITRedirect" */
     451,    /* "dNSDomain" */
     495,    /* "dSAQuality" */
     434,    /* "data" */
     390,    /* "dcobject" */
     140,    /* "deltaCRL" */
     891,    /* "deltaRevocationList" */
     107,    /* "description" */
     871,    /* "destinationIndicator" */
     947,    /* "dh-cofactor-kdf" */
     946,    /* "dh-std-kdf" */
      28,    /* "dhKeyAgreement" */
     941,    /* "dhSinglePass-cofactorDH-sha1kdf-scheme" */
     942,    /* "dhSinglePass-cofactorDH-sha224kdf-scheme" */
     943,    /* "dhSinglePass-cofactorDH-sha256kdf-scheme" */
     944,    /* "dhSinglePass-cofactorDH-sha384kdf-scheme" */
     945,    /* "dhSinglePass-cofactorDH-sha512kdf-scheme" */
     936,    /* "dhSinglePass-stdDH-sha1kdf-scheme" */
     937,    /* "dhSinglePass-stdDH-sha224kdf-scheme" */
     938,    /* "dhSinglePass-stdDH-sha256kdf-scheme" */
     939,    /* "dhSinglePass-stdDH-sha384kdf-scheme" */
     940,    /* "dhSinglePass-stdDH-sha512kdf-scheme" */
     920,    /* "dhpublicnumber" */
     382,    /* "directory" */
     887,    /* "distinguishedName" */
     892,    /* "dmdName" */
     174,    /* "dnQualifier" */
    1092,    /* "dnsName" */
     447,    /* "document" */
     471,    /* "documentAuthor" */
     468,    /* "documentIdentifier" */
     472,    /* "documentLocation" */
     502,    /* "documentPublisher" */
     449,    /* "documentSeries" */
     469,    /* "documentTitle" */
     470,    /* "documentVersion" */
     392,    /* "domain" */
     452,    /* "domainRelatedObject" */
     802,    /* "dsa_with_SHA224" */
     803,    /* "dsa_with_SHA256" */
    1152,    /* "dstu28147" */
    1154,    /* "dstu28147-cfb" */
    1153,    /* "dstu28147-ofb" */
    1155,    /* "dstu28147-wrap" */
    1157,    /* "dstu34311" */
    1159,    /* "dstu4145be" */
    1158,    /* "dstu4145le" */
     791,    /* "ecdsa-with-Recommended" */
     416,    /* "ecdsa-with-SHA1" */
     793,    /* "ecdsa-with-SHA224" */
     794,    /* "ecdsa-with-SHA256" */
     795,    /* "ecdsa-with-SHA384" */
     796,    /* "ecdsa-with-SHA512" */
     792,    /* "ecdsa-with-Specified" */
      48,    /* "emailAddress" */
     132,    /* "emailProtection" */
     885,    /* "enhancedSearchGuide" */
     389,    /* "enterprises" */
     384,    /* "experimental" */
     172,    /* "extReq" */
      56,    /* "extendedCertificateAttributes" */
     126,    /* "extendedKeyUsage" */
     372,    /* "extendedStatus" */
     867,    /* "facsimileTelephoneNumber" */
     462,    /* "favouriteDrink" */
    1126,    /* "ffdhe2048" */
    1127,    /* "ffdhe3072" */
    1128,    /* "ffdhe4096" */
    1129,    /* "ffdhe6144" */
    1130,    /* "ffdhe8192" */
     857,    /* "freshestCRL" */
     453,    /* "friendlyCountry" */
     490,    /* "friendlyCountryName" */
     156,    /* "friendlyName" */
     509,    /* "generationQualifier" */
     815,    /* "gost-mac" */
     976,    /* "gost-mac-12" */
     811,    /* "gost2001" */
     851,    /* "gost2001cc" */
     979,    /* "gost2012_256" */
     980,    /* "gost2012_512" */
     813,    /* "gost89" */
    1009,    /* "gost89-cbc" */
     814,    /* "gost89-cnt" */
     975,    /* "gost89-cnt-12" */
    1011,    /* "gost89-ctr" */
    1010,    /* "gost89-ecb" */
     812,    /* "gost94" */
     850,    /* "gost94cc" */
    1015,    /* "grasshopper-cbc" */
    1016,    /* "grasshopper-cfb" */
    1013,    /* "grasshopper-ctr" */
    1012,    /* "grasshopper-ecb" */
    1017,    /* "grasshopper-mac" */
    1014,    /* "grasshopper-ofb" */
    1156,    /* "hmacWithDstu34311" */
     797,    /* "hmacWithMD5" */
     163,    /* "hmacWithSHA1" */
     798,    /* "hmacWithSHA224" */
     799,    /* "hmacWithSHA256" */
     800,    /* "hmacWithSHA384" */
     801,    /* "hmacWithSHA512" */
    1193,    /* "hmacWithSHA512-224" */
    1194,    /* "hmacWithSHA512-256" */
     432,    /* "holdInstructionCallIssuer" */
     430,    /* "holdInstructionCode" */
     431,    /* "holdInstructionNone" */
     433,    /* "holdInstructionReject" */
     486,    /* "homePostalAddress" */
     473,    /* "homeTelephoneNumber" */
     466,    /* "host" */
     889,    /* "houseIdentifier" */
     442,    /* "iA5StringSyntax" */
     783,    /* "id-DHBasedMac" */
     824,    /* "id-Gost28147-89-CryptoPro-A-ParamSet" */
     825,    /* "id-Gost28147-89-CryptoPro-B-ParamSet" */
     826,    /* "id-Gost28147-89-CryptoPro-C-ParamSet" */
     827,    /* "id-Gost28147-89-CryptoPro-D-ParamSet" */
     819,    /* "id-Gost28147-89-CryptoPro-KeyMeshing" */
     829,    /* "id-Gost28147-89-CryptoPro-Oscar-1-0-ParamSet" */
     828,    /* "id-Gost28147-89-CryptoPro-Oscar-1-1-ParamSet" */
     830,    /* "id-Gost28147-89-CryptoPro-RIC-1-ParamSet" */
     820,    /* "id-Gost28147-89-None-KeyMeshing" */
     823,    /* "id-Gost28147-89-TestParamSet" */
     849,    /* "id-Gost28147-89-cc" */
     840,    /* "id-GostR3410-2001-CryptoPro-A-ParamSet" */
     841,    /* "id-GostR3410-2001-CryptoPro-B-ParamSet" */
     842,    /* "id-GostR3410-2001-CryptoPro-C-ParamSet" */
     843,    /* "id-GostR3410-2001-CryptoPro-XchA-ParamSet" */
     844,    /* "id-GostR3410-2001-CryptoPro-XchB-ParamSet" */
     854,    /* "id-GostR3410-2001-ParamSet-cc" */
     839,    /* "id-GostR3410-2001-TestParamSet" */
     817,    /* "id-GostR3410-2001DH" */
     832,    /* "id-GostR3410-94-CryptoPro-A-ParamSet" */
     833,    /* "id-GostR3410-94-CryptoPro-B-ParamSet" */
     834,    /* "id-GostR3410-94-CryptoPro-C-ParamSet" */
     835,    /* "id-GostR3410-94-CryptoPro-D-ParamSet" */
     836,    /* "id-GostR3410-94-CryptoPro-XchA-ParamSet" */
     837,    /* "id-GostR3410-94-CryptoPro-XchB-ParamSet" */
     838,    /* "id-GostR3410-94-CryptoPro-XchC-ParamSet" */
     831,    /* "id-GostR3410-94-TestParamSet" */
     845,    /* "id-GostR3410-94-a" */
     846,    /* "id-GostR3410-94-aBis" */
     847,    /* "id-GostR3410-94-b" */
     848,    /* "id-GostR3410-94-bBis" */
     818,    /* "id-GostR3410-94DH" */
     822,    /* "id-GostR3411-94-CryptoProParamSet" */
     821,    /* "id-GostR3411-94-TestParamSet" */
     807,    /* "id-GostR3411-94-with-GostR3410-2001" */
     853,    /* "id-GostR3411-94-with-GostR3410-2001-cc" */
     808,    /* "id-GostR3411-94-with-GostR3410-94" */
     852,    /* "id-GostR3411-94-with-GostR3410-94-cc" */
     810,    /* "id-HMACGostR3411-94" */
     782,    /* "id-PasswordBasedMAC" */
     266,    /* "id-aca" */
     355,    /* "id-aca-accessIdentity" */
     354,    /* "id-aca-authenticationInfo" */
     356,    /* "id-aca-chargingIdentity" */
     399,    /* "id-aca-encAttrs" */
     357,    /* "id-aca-group" */
     358,    /* "id-aca-role" */
     176,    /* "id-ad" */
     896,    /* "id-aes128-CCM" */
     895,    /* "id-aes128-GCM" */
     788,    /* "id-aes128-wrap" */
     897,    /* "id-aes128-wrap-pad" */
     899,    /* "id-aes192-CCM" */
     898,    /* "id-aes192-GCM" */
     789,    /* "id-aes192-wrap" */
     900,    /* "id-aes192-wrap-pad" */
     902,    /* "id-aes256-CCM" */
     901,    /* "id-aes256-GCM" */
     790,    /* "id-aes256-wrap" */
     903,    /* "id-aes256-wrap-pad" */
     262,    /* "id-alg" */
     893,    /* "id-alg-PWRI-KEK" */
     323,    /* "id-alg-des40" */
     326,    /* "id-alg-dh-pop" */
     325,    /* "id-alg-dh-sig-hmac-sha1" */
     324,    /* "id-alg-noSignature" */
     907,    /* "id-camellia128-wrap" */
     908,    /* "id-camellia192-wrap" */
     909,    /* "id-camellia256-wrap" */
     268,    /* "id-cct" */
     361,    /* "id-cct-PKIData" */
     362,    /* "id-cct-PKIResponse" */
     360,    /* "id-cct-crs" */
      81,    /* "id-ce" */
     680,    /* "id-characteristic-two-basis" */
     263,    /* "id-cmc" */
     334,    /* "id-cmc-addExtensions" */
     346,    /* "id-cmc-confirmCertAcceptance" */
     330,    /* "id-cmc-dataReturn" */
     336,    /* "id-cmc-decryptedPOP" */
     335,    /* "id-cmc-encryptedPOP" */
     339,    /* "id-cmc-getCRL" */
     338,    /* "id-cmc-getCert" */
     328,    /* "id-cmc-identification" */
     329,    /* "id-cmc-identityProof" */
     337,    /* "id-cmc-lraPOPWitness" */
     344,    /* "id-cmc-popLinkRandom" */
     345,    /* "id-cmc-popLinkWitness" */
     343,    /* "id-cmc-queryPending" */
     333,    /* "id-cmc-recipientNonce" */
     341,    /* "id-cmc-regInfo" */
     342,    /* "id-cmc-responseInfo" */
     340,    /* "id-cmc-revokeRequest" */
     332,    /* "id-cmc-senderNonce" */
     327,    /* "id-cmc-statusInfo" */
     331,    /* "id-cmc-transactionId" */
     787,    /* "id-ct-asciiTextWithCRLF" */
    1060,    /* "id-ct-xml" */
    1108,    /* "id-dsa-with-sha3-224" */
    1109,    /* "id-dsa-with-sha3-256" */
    1110,    /* "id-dsa-with-sha3-384" */
    1111,    /* "id-dsa-with-sha3-512" */
    1106,    /* "id-dsa-with-sha384" */
    1107,    /* "id-dsa-with-sha512" */
     408,    /* "id-ecPublicKey" */
    1112,    /* "id-ecdsa-with-sha3-224" */
    1113,    /* "id-ecdsa-with-sha3-256" */
    1114,    /* "id-ecdsa-with-sha3-384" */
    1115,    /* "id-ecdsa-with-sha3-512" */
     508,    /* "id-hex-multipart-message" */
     507,    /* "id-hex-partial-message" */
    1102,    /* "id-hmacWithSHA3-224" */
    1103,    /* "id-hmacWithSHA3-256" */
    1104,    /* "id-hmacWithSHA3-384" */
    1105,    /* "id-hmacWithSHA3-512" */
     260,    /* "id-it" */
     302,    /* "id-it-caKeyUpdateInfo" */
     298,    /* "id-it-caProtEncCert" */
     311,    /* "id-it-confirmWaitTime" */
     303,    /* "id-it-currentCRL" */
     300,    /* "id-it-encKeyPairTypes" */
     310,    /* "id-it-implicitConfirm" */
     308,    /* "id-it-keyPairParamRep" */
     307,    /* "id-it-keyPairParamReq" */
     312,    /* "id-it-origPKIMessage" */
     301,    /* "id-it-preferredSymmAlg" */
     309,    /* "id-it-revPassphrase" */
     299,    /* "id-it-signKeyPairTypes" */
     305,    /* "id-it-subscriptionRequest" */
     306,    /* "id-it-subscriptionResponse" */
     784,    /* "id-it-suppLangTags" */
     304,    /* "id-it-unsupportedOIDs" */
     128,    /* "id-kp" */
     280,    /* "id-mod-attribute-cert" */
     274,    /* "id-mod-cmc" */
     277,    /* "id-mod-cmp" */
     284,    /* "id-mod-cmp2000" */
     273,    /* "id-mod-crmf" */
     283,    /* "id-mod-dvcs" */
     275,    /* "id-mod-kea-profile-88" */
     276,    /* "id-mod-kea-profile-93" */
     282,    /* "id-mod-ocsp" */
     278,    /* "id-mod-qualified-cert-88" */
     279,    /* "id-mod-qualified-cert-93" */
     281,    /* "id-mod-timestamp-protocol" */
     264,    /* "id-on" */
     858,    /* "id-on-permanentIdentifier" */
     347,    /* "id-on-personalData" */
     265,    /* "id-pda" */
     352,    /* "id-pda-countryOfCitizenship" */
     353,    /* "id-pda-countryOfResidence" */
     348,    /* "id-pda-dateOfBirth" */
     351,    /* "id-pda-gender" */
     349,    /* "id-pda-placeOfBirth" */
     175,    /* "id-pe" */
    1031,    /* "id-pkinit" */
     261,    /* "id-pkip" */
     258,    /* "id-pkix-mod" */
     269,    /* "id-pkix1-explicit-88" */
     271,    /* "id-pkix1-explicit-93" */
     270,    /* "id-pkix1-implicit-88" */
     272,    /* "id-pkix1-implicit-93" */
     662,    /* "id-ppl" */
     664,    /* "id-ppl-anyLanguage" */
     667,    /* "id-ppl-independent" */
     665,    /* "id-ppl-inheritAll" */
     267,    /* "id-qcs" */
     359,    /* "id-qcs-pkixQCSyntax-v1" */
     259,    /* "id-qt" */
     164,    /* "id-qt-cps" */
     165,    /* "id-qt-unotice" */
     313,    /* "id-regCtrl" */
     316,    /* "id-regCtrl-authenticator" */
     319,    /* "id-regCtrl-oldCertID" */
     318,    /* "id-regCtrl-pkiArchiveOptions" */
     317,    /* "id-regCtrl-pkiPublicationInfo" */
     320,    /* "id-regCtrl-protocolEncrKey" */
     315,    /* "id-regCtrl-regToken" */
     314,    /* "id-regInfo" */
     322,    /* "id-regInfo-certReq" */
     321,    /* "id-regInfo-utf8Pairs" */
    1116,    /* "id-rsassa-pkcs1-v1_5-with-sha3-224" */
    1117,    /* "id-rsassa-pkcs1-v1_5-with-sha3-256" */
    1118,    /* "id-rsassa-pkcs1-v1_5-with-sha3-384" */
    1119,    /* "id-rsassa-pkcs1-v1_5-with-sha3-512" */
     973,    /* "id-scrypt" */
     512,    /* "id-set" */
     191,    /* "id-smime-aa" */
     215,    /* "id-smime-aa-contentHint" */
     218,    /* "id-smime-aa-contentIdentifier" */
     221,    /* "id-smime-aa-contentReference" */
     240,    /* "id-smime-aa-dvcs-dvc" */
     217,    /* "id-smime-aa-encapContentType" */
     222,    /* "id-smime-aa-encrypKeyPref" */
     220,    /* "id-smime-aa-equivalentLabels" */
     232,    /* "id-smime-aa-ets-CertificateRefs" */
     233,    /* "id-smime-aa-ets-RevocationRefs" */
     238,    /* "id-smime-aa-ets-archiveTimeStamp" */
     237,    /* "id-smime-aa-ets-certCRLTimestamp" */
     234,    /* "id-smime-aa-ets-certValues" */
     227,    /* "id-smime-aa-ets-commitmentType" */
     231,    /* "id-smime-aa-ets-contentTimestamp" */
     236,    /* "id-smime-aa-ets-escTimeStamp" */
     230,    /* "id-smime-aa-ets-otherSigCert" */
     235,    /* "id-smime-aa-ets-revocationValues" */
     226,    /* "id-smime-aa-ets-sigPolicyId" */
     229,    /* "id-smime-aa-ets-signerAttr" */
     228,    /* "id-smime-aa-ets-signerLocation" */
     219,    /* "id-smime-aa-macValue" */
     214,    /* "id-smime-aa-mlExpandHistory" */
     216,    /* "id-smime-aa-msgSigDigest" */
     212,    /* "id-smime-aa-receiptRequest" */
     213,    /* "id-smime-aa-securityLabel" */
     239,    /* "id-smime-aa-signatureType" */
     223,    /* "id-smime-aa-signingCertificate" */
    1086,    /* "id-smime-aa-signingCertificateV2" */
     224,    /* "id-smime-aa-smimeEncryptCerts" */
     225,    /* "id-smime-aa-timeStampToken" */
     192,    /* "id-smime-alg" */
     243,    /* "id-smime-alg-3DESwrap" */
     246,    /* "id-smime-alg-CMS3DESwrap" */
     247,    /* "id-smime-alg-CMSRC2wrap" */
     245,    /* "id-smime-alg-ESDH" */
     241,    /* "id-smime-alg-ESDHwith3DES" */
     242,    /* "id-smime-alg-ESDHwithRC2" */
     244,    /* "id-smime-alg-RC2wrap" */
     193,    /* "id-smime-cd" */
     248,    /* "id-smime-cd-ldap" */
     190,    /* "id-smime-ct" */
     210,    /* "id-smime-ct-DVCSRequestData" */
     211,    /* "id-smime-ct-DVCSResponseData" */
     208,    /* "id-smime-ct-TDTInfo" */
     207,    /* "id-smime-ct-TSTInfo" */
     205,    /* "id-smime-ct-authData" */
    1059,    /* "id-smime-ct-authEnvelopedData" */
     786,    /* "id-smime-ct-compressedData" */
    1058,    /* "id-smime-ct-contentCollection" */
     209,    /* "id-smime-ct-contentInfo" */
     206,    /* "id-smime-ct-publishCert" */
     204,    /* "id-smime-ct-receipt" */
     195,    /* "id-smime-cti" */
     255,    /* "id-smime-cti-ets-proofOfApproval" */
     256,    /* "id-smime-cti-ets-proofOfCreation" */
     253,    /* "id-smime-cti-ets-proofOfDelivery" */
     251,    /* "id-smime-cti-ets-proofOfOrigin" */
     252,    /* "id-smime-cti-ets-proofOfReceipt" */
     254,    /* "id-smime-cti-ets-proofOfSender" */
     189,    /* "id-smime-mod" */
     196,    /* "id-smime-mod-cms" */
     197,    /* "id-smime-mod-ess" */
     202,    /* "id-smime-mod-ets-eSigPolicy-88" */
     203,    /* "id-smime-mod-ets-eSigPolicy-97" */
     200,    /* "id-smime-mod-ets-eSignature-88" */
     201,    /* "id-smime-mod-ets-eSignature-97" */
     199,    /* "id-smime-mod-msg-v3" */
     198,    /* "id-smime-mod-oid" */
     194,    /* "id-smime-spq" */
     250,    /* "id-smime-spq-ets-sqt-unotice" */
     249,    /* "id-smime-spq-ets-sqt-uri" */
     974,    /* "id-tc26" */
     991,    /* "id-tc26-agreement" */
     992,    /* "id-tc26-agreement-gost-3410-2012-256" */
     993,    /* "id-tc26-agreement-gost-3410-2012-512" */
     977,    /* "id-tc26-algorithms" */
     990,    /* "id-tc26-cipher" */
    1001,    /* "id-tc26-cipher-constants" */
    1176,    /* "id-tc26-cipher-gostr3412-2015-kuznyechik" */
    1177,    /* "id-tc26-cipher-gostr3412-2015-kuznyechik-ctracpkm" */
    1178,    /* "id-tc26-cipher-gostr3412-2015-kuznyechik-ctracpkm-omac" */
    1173,    /* "id-tc26-cipher-gostr3412-2015-magma" */
    1174,    /* "id-tc26-cipher-gostr3412-2015-magma-ctracpkm" */
    1175,    /* "id-tc26-cipher-gostr3412-2015-magma-ctracpkm-omac" */
     994,    /* "id-tc26-constants" */
     981,    /* "id-tc26-digest" */
    1000,    /* "id-tc26-digest-constants" */
    1002,    /* "id-tc26-gost-28147-constants" */
    1003,    /* "id-tc26-gost-28147-param-Z" */
    1147,    /* "id-tc26-gost-3410-2012-256-constants" */
    1148,    /* "id-tc26-gost-3410-2012-256-paramSetA" */
    1184,    /* "id-tc26-gost-3410-2012-256-paramSetB" */
    1185,    /* "id-tc26-gost-3410-2012-256-paramSetC" */
    1186,    /* "id-tc26-gost-3410-2012-256-paramSetD" */
     996,    /* "id-tc26-gost-3410-2012-512-constants" */
     998,    /* "id-tc26-gost-3410-2012-512-paramSetA" */
     999,    /* "id-tc26-gost-3410-2012-512-paramSetB" */
    1149,    /* "id-tc26-gost-3410-2012-512-paramSetC" */
     997,    /* "id-tc26-gost-3410-2012-512-paramSetTest" */
     988,    /* "id-tc26-hmac-gost-3411-2012-256" */
     989,    /* "id-tc26-hmac-gost-3411-2012-512" */
     987,    /* "id-tc26-mac" */
     978,    /* "id-tc26-sign" */
     995,    /* "id-tc26-sign-constants" */
     984,    /* "id-tc26-signwithdigest" */
     985,    /* "id-tc26-signwithdigest-gost3410-2012-256" */
     986,    /* "id-tc26-signwithdigest-gost3410-2012-512" */
    1179,    /* "id-tc26-wrap" */
    1182,    /* "id-tc26-wrap-gostr3412-2015-kuznyechik" */
    1183,    /* "id-tc26-wrap-gostr3412-2015-kuznyechik-kexp15" */
    1180,    /* "id-tc26-wrap-gostr3412-2015-magma" */
    1181,    /* "id-tc26-wrap-gostr3412-2015-magma-kexp15" */
     676,    /* "identified-organization" */
    1170,    /* "ieee" */
    1171,    /* "ieee-siswg" */
     461,    /* "info" */
     748,    /* "inhibitAnyPolicy" */
     101,    /* "initials" */
     647,    /* "international-organizations" */
     869,    /* "internationaliSDNNumber" */
     142,    /* "invalidityDate" */
     294,    /* "ipsecEndSystem" */
    1022,    /* "ipsecIKE" */
     295,    /* "ipsecTunnel" */
     296,    /* "ipsecUser" */
      86,    /* "issuerAltName" */
    1008,    /* "issuerSignTool" */
     770,    /* "issuingDistributionPoint" */
     492,    /* "janetMailbox" */
     957,    /* "jurisdictionC" */
     955,    /* "jurisdictionL" */
     956,    /* "jurisdictionST" */
     150,    /* "keyBag" */
      83,    /* "keyUsage" */
     477,    /* "lastModifiedBy" */
     476,    /* "lastModifiedTime" */
     157,    /* "localKeyID" */
     480,    /* "mXRecord" */
    1190,    /* "magma-cbc" */
    1191,    /* "magma-cfb" */
    1188,    /* "magma-ctr" */
    1187,    /* "magma-ecb" */
    1192,    /* "magma-mac" */
    1189,    /* "magma-ofb" */
     460,    /* "mail" */
     493,    /* "mailPreferenceOption" */
     467,    /* "manager" */
     982,    /* "md_gost12_256" */
     983,    /* "md_gost12_512" */
     809,    /* "md_gost94" */
     875,    /* "member" */
     182,    /* "member-body" */
      51,    /* "messageDigest" */
     383,    /* "mgmt" */
     504,    /* "mime-mhs" */
     506,    /* "mime-mhs-bodies" */
     505,    /* "mime-mhs-headings" */
     488,    /* "mobileTelephoneNumber" */
     136,    /* "msCTLSign" */
     135,    /* "msCodeCom" */
     134,    /* "msCodeInd" */
     138,    /* "msEFS" */
     171,    /* "msExtReq" */
     137,    /* "msSGC" */
     648,    /* "msSmartcardLogin" */
     649,    /* "msUPN" */
    1091,    /* "n3" */
     481,    /* "nSRecord" */
     173,    /* "name" */
     666,    /* "nameConstraints" */
     369,    /* "noCheck" */
     403,    /* "noRevAvail" */
      72,    /* "nsBaseUrl" */
      76,    /* "nsCaPolicyUrl" */
      74,    /* "nsCaRevocationUrl" */
      58,    /* "nsCertExt" */
      79,    /* "nsCertSequence" */
      71,    /* "nsCertType" */
      78,    /* "nsComment" */
      59,    /* "nsDataType" */
      75,    /* "nsRenewalUrl" */
      73,    /* "nsRevocationUrl" */
     139,    /* "nsSGC" */
      77,    /* "nsSslServerName" */
     681,    /* "onBasis" */
    1089,    /* "organizationIdentifier" */
     491,    /* "organizationalStatus" */
    1141,    /* "oscca" */
     475,    /* "otherMailbox" */
     876,    /* "owner" */
     489,    /* "pagerTelephoneNumber" */
     374,    /* "path" */
     112,    /* "pbeWithMD5AndCast5CBC" */
     499,    /* "personalSignature" */
     487,    /* "personalTitle" */
     464,    /* "photo" */
     863,    /* "physicalDeliveryOfficeName" */
     437,    /* "pilot" */
     439,    /* "pilotAttributeSyntax" */
     438,    /* "pilotAttributeType" */
     479,    /* "pilotAttributeType27" */
     456,    /* "pilotDSA" */
     441,    /* "pilotGroups" */
     444,    /* "pilotObject" */
     440,    /* "pilotObjectClass" */
     455,    /* "pilotOrganization" */
     445,    /* "pilotPerson" */
    1032,    /* "pkInitClientAuth" */
    1033,    /* "pkInitKDC" */
       2,    /* "pkcs" */
     186,    /* "pkcs1" */
      27,    /* "pkcs3" */
     187,    /* "pkcs5" */
      20,    /* "pkcs7" */
      21,    /* "pkcs7-data" */
      25,    /* "pkcs7-digestData" */
      26,    /* "pkcs7-encryptedData" */
      23,    /* "pkcs7-envelopedData" */
      24,    /* "pkcs7-signedAndEnvelopedData" */
      22,    /* "pkcs7-signedData" */
     151,    /* "pkcs8ShroudedKeyBag" */
      47,    /* "pkcs9" */
     401,    /* "policyConstraints" */
     747,    /* "policyMappings" */
     862,    /* "postOfficeBox" */
     861,    /* "postalAddress" */
     661,    /* "postalCode" */
     683,    /* "ppBasis" */
     872,    /* "preferredDeliveryMethod" */
     873,    /* "presentationAddress" */
     816,    /* "prf-gostr3411-94" */
     406,    /* "prime-field" */
     409,    /* "prime192v1" */
     410,    /* "prime192v2" */
     411,    /* "prime192v3" */
     412,    /* "prime239v1" */
     413,    /* "prime239v2" */
     414,    /* "prime239v3" */
     415,    /* "prime256v1" */
     385,    /* "private" */
      84,    /* "privateKeyUsagePeriod" */
     886,    /* "protocolInformation" */
     663,    /* "proxyCertInfo" */
     510,    /* "pseudonym" */
     435,    /* "pss" */
     286,    /* "qcStatements" */
     457,    /* "qualityLabelledData" */
     450,    /* "rFC822localPart" */
     870,    /* "registeredAddress" */
     400,    /* "role" */
     877,    /* "roleOccupant" */
     448,    /* "room" */
     463,    /* "roomNumber" */
       6,    /* "rsaEncryption" */
     644,    /* "rsaOAEPEncryptionSET" */
     377,    /* "rsaSignature" */
       1,    /* "rsadsi" */
     482,    /* "sOARecord" */
     155,    /* "safeContentsBag" */
     291,    /* "sbgp-autonomousSysNum" */
     290,    /* "sbgp-ipAddrBlock" */
     292,    /* "sbgp-routerIdentifier" */
     159,    /* "sdsiCertificate" */
     859,    /* "searchGuide" */
     704,    /* "secp112r1" */
     705,    /* "secp112r2" */
     706,    /* "secp128r1" */
     707,    /* "secp128r2" */
     708,    /* "secp160k1" */
     709,    /* "secp160r1" */
     710,    /* "secp160r2" */
     711,    /* "secp192k1" */
     712,    /* "secp224k1" */
     713,    /* "secp224r1" */
     714,    /* "secp256k1" */
     715,    /* "secp384r1" */
     716,    /* "secp521r1" */
     154,    /* "secretBag" */
     474,    /* "secretary" */
     717,    /* "sect113r1" */
     718,    /* "sect113r2" */
     719,    /* "sect131r1" */
     720,    /* "sect131r2" */
     721,    /* "sect163k1" */
     722,    /* "sect163r1" */
     723,    /* "sect163r2" */
     724,    /* "sect193r1" */
     725,    /* "sect193r2" */
     726,    /* "sect233k1" */
     727,    /* "sect233r1" */
     728,    /* "sect239k1" */
     729,    /* "sect283k1" */
     730,    /* "sect283r1" */
     731,    /* "sect409k1" */
     732,    /* "sect409r1" */
     733,    /* "sect571k1" */
     734,    /* "sect571r1" */
    1025,    /* "secureShellClient" */
    1026,    /* "secureShellServer" */
     386,    /* "security" */
     878,    /* "seeAlso" */
     394,    /* "selected-attribute-types" */
    1029,    /* "sendOwner" */
    1030,    /* "sendProxiedOwner" */
    1028,    /* "sendProxiedRouter" */
    1027,    /* "sendRouter" */
     105,    /* "serialNumber" */
     129,    /* "serverAuth" */
     371,    /* "serviceLocator" */
     625,    /* "set-addPolicy" */
     515,    /* "set-attr" */
     518,    /* "set-brand" */
     638,    /* "set-brand-AmericanExpress" */
     637,    /* "set-brand-Diners" */
     636,    /* "set-brand-IATA-ATA" */
     639,    /* "set-brand-JCB" */
     641,    /* "set-brand-MasterCard" */
     642,    /* "set-brand-Novus" */
     640,    /* "set-brand-Visa" */
     517,    /* "set-certExt" */
     513,    /* "set-ctype" */
     514,    /* "set-msgExt" */
     516,    /* "set-policy" */
     607,    /* "set-policy-root" */
     624,    /* "set-rootKeyThumb" */
     620,    /* "setAttr-Cert" */
     631,    /* "setAttr-GenCryptgrm" */
     623,    /* "setAttr-IssCap" */
     628,    /* "setAttr-IssCap-CVM" */
     630,    /* "setAttr-IssCap-Sig" */
     629,    /* "setAttr-IssCap-T2" */
     621,    /* "setAttr-PGWYcap" */
     635,    /* "setAttr-SecDevSig" */
     632,    /* "setAttr-T2Enc" */
     633,    /* "setAttr-T2cleartxt" */
     634,    /* "setAttr-TokICCsig" */
     627,    /* "setAttr-Token-B0Prime" */
     626,    /* "setAttr-Token-EMV" */
     622,    /* "setAttr-TokenType" */
     619,    /* "setCext-IssuerCapabilities" */
     615,    /* "setCext-PGWYcapabilities" */
     616,    /* "setCext-TokenIdentifier" */
     618,    /* "setCext-TokenType" */
     617,    /* "setCext-Track2Data" */
     611,    /* "setCext-cCertRequired" */
     609,    /* "setCext-certType" */
     608,    /* "setCext-hashedRoot" */
     610,    /* "setCext-merchData" */
     613,    /* "setCext-setExt" */
     614,    /* "setCext-setQualf" */
     612,    /* "setCext-tunneling" */
     540,    /* "setct-AcqCardCodeMsg" */
     576,    /* "setct-AcqCardCodeMsgTBE" */
     570,    /* "setct-AuthReqTBE" */
     534,    /* "setct-AuthReqTBS" */
     527,    /* "setct-AuthResBaggage" */
     571,    /* "setct-AuthResTBE" */
     572,    /* "setct-AuthResTBEX" */
     535,    /* "setct-AuthResTBS" */
     536,    /* "setct-AuthResTBSX" */
     528,    /* "setct-AuthRevReqBaggage" */
     577,    /* "setct-AuthRevReqTBE" */
     541,    /* "setct-AuthRevReqTBS" */
     529,    /* "setct-AuthRevResBaggage" */
     542,    /* "setct-AuthRevResData" */
     578,    /* "setct-AuthRevResTBE" */
     579,    /* "setct-AuthRevResTBEB" */
     543,    /* "setct-AuthRevResTBS" */
     573,    /* "setct-AuthTokenTBE" */
     537,    /* "setct-AuthTokenTBS" */
     600,    /* "setct-BCIDistributionTBS" */
     558,    /* "setct-BatchAdminReqData" */
     592,    /* "setct-BatchAdminReqTBE" */
     559,    /* "setct-BatchAdminResData" */
     593,    /* "setct-BatchAdminResTBE" */
     599,    /* "setct-CRLNotificationResTBS" */
     598,    /* "setct-CRLNotificationTBS" */
     580,    /* "setct-CapReqTBE" */
     581,    /* "setct-CapReqTBEX" */
     544,    /* "setct-CapReqTBS" */
     545,    /* "setct-CapReqTBSX" */
     546,    /* "setct-CapResData" */
     582,    /* "setct-CapResTBE" */
     583,    /* "setct-CapRevReqTBE" */
     584,    /* "setct-CapRevReqTBEX" */
     547,    /* "setct-CapRevReqTBS" */
     548,    /* "setct-CapRevReqTBSX" */
     549,    /* "setct-CapRevResData" */
     585,    /* "setct-CapRevResTBE" */
     538,    /* "setct-CapTokenData" */
     530,    /* "setct-CapTokenSeq" */
     574,    /* "setct-CapTokenTBE" */
     575,    /* "setct-CapTokenTBEX" */
     539,    /* "setct-CapTokenTBS" */
     560,    /* "setct-CardCInitResTBS" */
     566,    /* "setct-CertInqReqTBS" */
     563,    /* "setct-CertReqData" */
     595,    /* "setct-CertReqTBE" */
     596,    /* "setct-CertReqTBEX" */
     564,    /* "setct-CertReqTBS" */
     565,    /* "setct-CertResData" */
     597,    /* "setct-CertResTBE" */
     586,    /* "setct-CredReqTBE" */
     587,    /* "setct-CredReqTBEX" */
     550,    /* "setct-CredReqTBS" */
     551,    /* "setct-CredReqTBSX" */
     552,    /* "setct-CredResData" */
     588,    /* "setct-CredResTBE" */
     589,    /* "setct-CredRevReqTBE" */
     590,    /* "setct-CredRevReqTBEX" */
     553,    /* "setct-CredRevReqTBS" */
     554,    /* "setct-CredRevReqTBSX" */
     555,    /* "setct-CredRevResData" */
     591,    /* "setct-CredRevResTBE" */
     567,    /* "setct-ErrorTBS" */
     526,    /* "setct-HODInput" */
     561,    /* "setct-MeAqCInitResTBS" */
     522,    /* "setct-OIData" */
     519,    /* "setct-PANData" */
     521,    /* "setct-PANOnly" */
     520,    /* "setct-PANToken" */
     556,    /* "setct-PCertReqData" */
     557,    /* "setct-PCertResTBS" */
     523,    /* "setct-PI" */
     532,    /* "setct-PI-TBS" */
     524,    /* "setct-PIData" */
     525,    /* "setct-PIDataUnsigned" */
     568,    /* "setct-PIDualSignedTBE" */
     569,    /* "setct-PIUnsignedTBE" */
     531,    /* "setct-PInitResData" */
     533,    /* "setct-PResData" */
     594,    /* "setct-RegFormReqTBE" */
     562,    /* "setct-RegFormResTBS" */
     606,    /* "setext-cv" */
     601,    /* "setext-genCrypt" */
     602,    /* "setext-miAuth" */
     604,    /* "setext-pinAny" */
     603,    /* "setext-pinSecure" */
     605,    /* "setext-track2" */
      52,    /* "signingTime" */
     454,    /* "simpleSecurityObject" */
     496,    /* "singleLevelQuality" */
    1142,    /* "sm-scheme" */
     387,    /* "snmpv2" */
     660,    /* "street" */
      85,    /* "subjectAltName" */
     769,    /* "subjectDirectoryAttributes" */
     398,    /* "subjectInfoAccess" */
      82,    /* "subjectKeyIdentifier" */
    1007,    /* "subjectSignTool" */
     498,    /* "subtreeMaximumQuality" */
     497,    /* "subtreeMinimumQuality" */
     890,    /* "supportedAlgorithms" */
     874,    /* "supportedApplicationContext" */
     402,    /* "targetInformation" */
     864,    /* "telephoneNumber" */
     866,    /* "teletexTerminalIdentifier" */
     865,    /* "telexNumber" */
     459,    /* "textEncodedORAddress" */
     293,    /* "textNotice" */
     133,    /* "timeStamping" */
     106,    /* "title" */
    1020,    /* "tlsfeature" */
     682,    /* "tpBasis" */
     375,    /* "trustRoot" */
    1151,    /* "ua-pki" */
    1160,    /* "uacurve0" */
    1161,    /* "uacurve1" */
    1162,    /* "uacurve2" */
    1163,    /* "uacurve3" */
    1164,    /* "uacurve4" */
    1165,    /* "uacurve5" */
    1166,    /* "uacurve6" */
    1167,    /* "uacurve7" */
    1168,    /* "uacurve8" */
    1169,    /* "uacurve9" */
     436,    /* "ucl" */
     102,    /* "uid" */
     888,    /* "uniqueMember" */
      55,    /* "unstructuredAddress" */
      49,    /* "unstructuredName" */
     880,    /* "userCertificate" */
     465,    /* "userClass" */
     879,    /* "userPassword" */
     373,    /* "valid" */
     678,    /* "wap" */
     679,    /* "wap-wsg" */
     735,    /* "wap-wsg-idm-ecid-wtls1" */
     743,    /* "wap-wsg-idm-ecid-wtls10" */
     744,    /* "wap-wsg-idm-ecid-wtls11" */
     745,    /* "wap-wsg-idm-ecid-wtls12" */
     736,    /* "wap-wsg-idm-ecid-wtls3" */
     737,    /* "wap-wsg-idm-ecid-wtls4" */
     738,    /* "wap-wsg-idm-ecid-wtls5" */
     739,    /* "wap-wsg-idm-ecid-wtls6" */
     740,    /* "wap-wsg-idm-ecid-wtls7" */
     741,    /* "wap-wsg-idm-ecid-wtls8" */
     742,    /* "wap-wsg-idm-ecid-wtls9" */
     804,    /* "whirlpool" */
     868,    /* "x121Address" */
     503,    /* "x500UniqueIdentifier" */
     158,    /* "x509Certificate" */
     160,    /* "x509Crl" */
    1093,    /* "x509ExtAdmission" */
};

#define NUM_LN 1186
static const unsigned int ln_objs[NUM_LN] = {
     363,    /* "AD Time Stamping" */
     405,    /* "ANSI X9.62" */
     368,    /* "Acceptable OCSP Responses" */
     910,    /* "Any Extended Key Usage" */
     664,    /* "Any language" */
     177,    /* "Authority Information Access" */
     365,    /* "Basic OCSP Response" */
     285,    /* "Biometric Info" */
     179,    /* "CA Issuers" */
     785,    /* "CA Repository" */
    1131,    /* "CMC Certificate Authority" */
    1132,    /* "CMC Registration Authority" */
     954,    /* "CT Certificate SCTs" */
     952,    /* "CT Precertificate Poison" */
     951,    /* "CT Precertificate SCTs" */
     953,    /* "CT Precertificate Signer" */
     131,    /* "Code Signing" */
    1024,    /* "Ctrl/Provision WAP Termination" */
    1023,    /* "Ctrl/provision WAP Access" */
    1159,    /* "DSTU 4145-2002 big endian" */
    1158,    /* "DSTU 4145-2002 little endian" */
    1152,    /* "DSTU Gost 28147-2009" */
    1154,    /* "DSTU Gost 28147-2009 CFB mode" */
    1153,    /* "DSTU Gost 28147-2009 OFB mode" */
    1155,    /* "DSTU Gost 28147-2009 key wrap" */
    1157,    /* "DSTU Gost 34311-95" */
    1160,    /* "DSTU curve 0" */
    1161,    /* "DSTU curve 1" */
    1162,    /* "DSTU curve 2" */
    1163,    /* "DSTU curve 3" */
    1164,    /* "DSTU curve 4" */
    1165,    /* "DSTU curve 5" */
    1166,    /* "DSTU curve 6" */
    1167,    /* "DSTU curve 7" */
    1168,    /* "DSTU curve 8" */
    1169,    /* "DSTU curve 9" */
     783,    /* "Diffie-Hellman based MAC" */
     382,    /* "Directory" */
     392,    /* "Domain" */
     132,    /* "E-mail Protection" */
    1087,    /* "ED25519" */
    1088,    /* "ED448" */
     389,    /* "Enterprises" */
     384,    /* "Experimental" */
     372,    /* "Extended OCSP Status" */
     172,    /* "Extension Request" */
     813,    /* "GOST 28147-89" */
     849,    /* "GOST 28147-89 Cryptocom ParamSet" */
     815,    /* "GOST 28147-89 MAC" */
    1003,    /* "GOST 28147-89 TC26 parameter set" */
     851,    /* "GOST 34.10-2001 Cryptocom" */
     850,    /* "GOST 34.10-94 Cryptocom" */
     811,    /* "GOST R 34.10-2001" */
     817,    /* "GOST R 34.10-2001 DH" */
    1148,    /* "GOST R 34.10-2012 (256 bit) ParamSet A" */
    1184,    /* "GOST R 34.10-2012 (256 bit) ParamSet B" */
    1185,    /* "GOST R 34.10-2012 (256 bit) ParamSet C" */
    1186,    /* "GOST R 34.10-2012 (256 bit) ParamSet D" */
     998,    /* "GOST R 34.10-2012 (512 bit) ParamSet A" */
     999,    /* "GOST R 34.10-2012 (512 bit) ParamSet B" */
    1149,    /* "GOST R 34.10-2012 (512 bit) ParamSet C" */
     997,    /* "GOST R 34.10-2012 (512 bit) testing parameter set" */
     979,    /* "GOST R 34.10-2012 with 256 bit modulus" */
     980,    /* "GOST R 34.10-2012 with 512 bit modulus" */
     985,    /* "GOST R 34.10-2012 with GOST R 34.11-2012 (256 bit)" */
     986,    /* "GOST R 34.10-2012 with GOST R 34.11-2012 (512 bit)" */
     812,    /* "GOST R 34.10-94" */
     818,    /* "GOST R 34.10-94 DH" */
     982,    /* "GOST R 34.11-2012 with 256 bit hash" */
     983,    /* "GOST R 34.11-2012 with 512 bit hash" */
     809,    /* "GOST R 34.11-94" */
     816,    /* "GOST R 34.11-94 PRF" */
     807,    /* "GOST R 34.11-94 with GOST R 34.10-2001" */
     853,    /* "GOST R 34.11-94 with GOST R 34.10-2001 Cryptocom" */
     808,    /* "GOST R 34.11-94 with GOST R 34.10-94" */
     852,    /* "GOST R 34.11-94 with GOST R 34.10-94 Cryptocom" */
     854,    /* "GOST R 3410-2001 Parameter Set Cryptocom" */
    1156,    /* "HMAC DSTU Gost 34311-95" */
     988,    /* "HMAC GOST 34.11-2012 256 bit" */
     989,    /* "HMAC GOST 34.11-2012 512 bit" */
     810,    /* "HMAC GOST 34.11-94" */
     432,    /* "Hold Instruction Call Issuer" */
     430,    /* "Hold Instruction Code" */
     431,    /* "Hold Instruction None" */
     433,    /* "Hold Instruction Reject" */
     634,    /* "ICC or token signature" */
    1171,    /* "IEEE Security in Storage Working Group" */
    1004,    /* "INN" */
     294,    /* "IPSec End System" */
     295,    /* "IPSec Tunnel" */
     296,    /* "IPSec User" */
    1140,    /* "ISO CN Member Body" */
     182,    /* "ISO Member Body" */
     183,    /* "ISO US Member Body" */
    1150,    /* "ISO-UA" */
     667,    /* "Independent" */
     665,    /* "Inherit all" */
     647,    /* "International Organizations" */
     142,    /* "Invalidity Date" */
     504,    /* "MIME MHS" */
     388,    /* "Mail" */
     383,    /* "Management" */
     417,    /* "Microsoft CSP Name" */
     135,    /* "Microsoft Commercial Code Signing" */
     138,    /* "Microsoft Encrypted File System" */
     171,    /* "Microsoft Extension Request" */
     134,    /* "Microsoft Individual Code Signing" */
     856,    /* "Microsoft Local Key set" */
     137,    /* "Microsoft Server Gated Crypto" */
     648,    /* "Microsoft Smartcard Login" */
     136,    /* "Microsoft Trust List Signing" */
     649,    /* "Microsoft User Principal Name" */
     393,    /* "NULL" */
     404,    /* "NULL" */
      72,    /* "Netscape Base Url" */
      76,    /* "Netscape CA Policy Url" */
      74,    /* "Netscape CA Revocation Url" */
      71,    /* "Netscape Cert Type" */
      58,    /* "Netscape Certificate Extension" */
      79,    /* "Netscape Certificate Sequence" */
      78,    /* "Netscape Comment" */
      57,    /* "Netscape Communications Corp." */
      59,    /* "Netscape Data Type" */
      75,    /* "Netscape Renewal Url" */
      73,    /* "Netscape Revocation Url" */
      77,    /* "Netscape SSL Server Name" */
     139,    /* "Netscape Server Gated Crypto" */
     178,    /* "OCSP" */
     370,    /* "OCSP Archive Cutoff" */
     367,    /* "OCSP CRL ID" */
     369,    /* "OCSP No Check" */
     366,    /* "OCSP Nonce" */
     371,    /* "OCSP Service Locator" */
     180,    /* "OCSP Signing" */
    1005,    /* "OGRN" */
     161,    /* "PBES2" */
      69,    /* "PBKDF2" */
     162,    /* "PBMAC1" */
    1032,    /* "PKINIT Client Auth" */
     127,    /* "PKIX" */
     858,    /* "Permanent Identifier" */
     164,    /* "Policy Qualifier CPS" */
     165,    /* "Policy Qualifier User Notice" */
     385,    /* "Private" */
    1093,    /* "Professional Information or basis for Admission" */
     663,    /* "Proxy Certificate Information" */
       1,    /* "RSA Data Security, Inc." */
       2,    /* "RSA Data Security, Inc. PKCS" */
    1116,    /* "RSA-SHA3-224" */
    1117,    /* "RSA-SHA3-256" */
    1118,    /* "RSA-SHA3-384" */
    1119,    /* "RSA-SHA3-512" */
     188,    /* "S/MIME" */
     167,    /* "S/MIME Capabilities" */
    1006,    /* "SNILS" */
     387,    /* "SNMPv2" */
    1025,    /* "SSH Client" */
    1026,    /* "SSH Server" */
     512,    /* "Secure Electronic Transactions" */
     386,    /* "Security" */
     394,    /* "Selected Attribute Types" */
    1029,    /* "Send Owner" */
    1030,    /* "Send Proxied Owner" */
    1028,    /* "Send Proxied Router" */
    1027,    /* "Send Router" */
    1033,    /* "Signing KDC Response" */
    1008,    /* "Signing Tool of Issuer" */
    1007,    /* "Signing Tool of Subject" */
     143,    /* "Strong Extranet ID" */
     398,    /* "Subject Information Access" */
    1020,    /* "TLS Feature" */
     130,    /* "TLS Web Client Authentication" */
     129,    /* "TLS Web Server Authentication" */
     133,    /* "Time Stamping" */
     375,    /* "Trust Root" */
    1034,    /* "X25519" */
    1035,    /* "X448" */
      12,    /* "X509" */
     402,    /* "X509v3 AC Targeting" */
     746,    /* "X509v3 Any Policy" */
      90,    /* "X509v3 Authority Key Identifier" */
      87,    /* "X509v3 Basic Constraints" */
     103,    /* "X509v3 CRL Distribution Points" */
      88,    /* "X509v3 CRL Number" */
     141,    /* "X509v3 CRL Reason Code" */
     771,    /* "X509v3 Certificate Issuer" */
      89,    /* "X509v3 Certificate Policies" */
     140,    /* "X509v3 Delta CRL Indicator" */
     126,    /* "X509v3 Extended Key Usage" */
     857,    /* "X509v3 Freshest CRL" */
     748,    /* "X509v3 Inhibit Any Policy" */
      86,    /* "X509v3 Issuer Alternative Name" */
     770,    /* "X509v3 Issuing Distribution Point" */
      83,    /* "X509v3 Key Usage" */
     666,    /* "X509v3 Name Constraints" */
     403,    /* "X509v3 No Revocation Available" */
     401,    /* "X509v3 Policy Constraints" */
     747,    /* "X509v3 Policy Mappings" */
      84,    /* "X509v3 Private Key Usage Period" */
      85,    /* "X509v3 Subject Alternative Name" */
     769,    /* "X509v3 Subject Directory Attributes" */
      82,    /* "X509v3 Subject Key Identifier" */
     920,    /* "X9.42 DH" */
     184,    /* "X9.57" */
     185,    /* "X9.57 CM ?" */
     478,    /* "aRecord" */
     289,    /* "aaControls" */
     287,    /* "ac-auditEntity" */
     397,    /* "ac-proxying" */
     288,    /* "ac-targeting" */
     446,    /* "account" */
     364,    /* "ad dvcs" */
     606,    /* "additional verification" */
     419,    /* "aes-128-cbc" */
     916,    /* "aes-128-cbc-hmac-sha1" */
     948,    /* "aes-128-cbc-hmac-sha256" */
     896,    /* "aes-128-ccm" */
     421,    /* "aes-128-cfb" */
     650,    /* "aes-128-cfb1" */
     653,    /* "aes-128-cfb8" */
     904,    /* "aes-128-ctr" */
     418,    /* "aes-128-ecb" */
     895,    /* "aes-128-gcm" */
     958,    /* "aes-128-ocb" */
     420,    /* "aes-128-ofb" */
     913,    /* "aes-128-xts" */
     423,    /* "aes-192-cbc" */
     917,    /* "aes-192-cbc-hmac-sha1" */
     949,    /* "aes-192-cbc-hmac-sha256" */
     899,    /* "aes-192-ccm" */
     425,    /* "aes-192-cfb" */
     651,    /* "aes-192-cfb1" */
     654,    /* "aes-192-cfb8" */
     905,    /* "aes-192-ctr" */
     422,    /* "aes-192-ecb" */
     898,    /* "aes-192-gcm" */
     959,    /* "aes-192-ocb" */
     424,    /* "aes-192-ofb" */
     427,    /* "aes-256-cbc" */
     918,    /* "aes-256-cbc-hmac-sha1" */
     950,    /* "aes-256-cbc-hmac-sha256" */
     902,    /* "aes-256-ccm" */
     429,    /* "aes-256-cfb" */
     652,    /* "aes-256-cfb1" */
     655,    /* "aes-256-cfb8" */
     906,    /* "aes-256-ctr" */
     426,    /* "aes-256-ecb" */
     901,    /* "aes-256-gcm" */
     960,    /* "aes-256-ocb" */
     428,    /* "aes-256-ofb" */
     914,    /* "aes-256-xts" */
     376,    /* "algorithm" */
    1066,    /* "aria-128-cbc" */
    1120,    /* "aria-128-ccm" */
    1067,    /* "aria-128-cfb" */
    1080,    /* "aria-128-cfb1" */
    1083,    /* "aria-128-cfb8" */
    1069,    /* "aria-128-ctr" */
    1065,    /* "aria-128-ecb" */
    1123,    /* "aria-128-gcm" */
    1068,    /* "aria-128-ofb" */
    1071,    /* "aria-192-cbc" */
    1121,    /* "aria-192-ccm" */
    1072,    /* "aria-192-cfb" */
    1081,    /* "aria-192-cfb1" */
    1084,    /* "aria-192-cfb8" */
    1074,    /* "aria-192-ctr" */
    1070,    /* "aria-192-ecb" */
    1124,    /* "aria-192-gcm" */
    1073,    /* "aria-192-ofb" */
    1076,    /* "aria-256-cbc" */
    1122,    /* "aria-256-ccm" */
    1077,    /* "aria-256-cfb" */
    1082,    /* "aria-256-cfb1" */
    1085,    /* "aria-256-cfb8" */
    1079,    /* "aria-256-ctr" */
    1075,    /* "aria-256-ecb" */
    1125,    /* "aria-256-gcm" */
    1078,    /* "aria-256-ofb" */
     484,    /* "associatedDomain" */
     485,    /* "associatedName" */
     501,    /* "audio" */
    1064,    /* "auth-any" */
    1049,    /* "auth-dss" */
    1047,    /* "auth-ecdsa" */
    1050,    /* "auth-gost01" */
    1051,    /* "auth-gost12" */
    1053,    /* "auth-null" */
    1048,    /* "auth-psk" */
    1046,    /* "auth-rsa" */
    1052,    /* "auth-srp" */
     882,    /* "authorityRevocationList" */
      91,    /* "bf-cbc" */
      93,    /* "bf-cfb" */
      92,    /* "bf-ecb" */
      94,    /* "bf-ofb" */
    1056,    /* "blake2b512" */
    1057,    /* "blake2s256" */
     921,    /* "brainpoolP160r1" */
     922,    /* "brainpoolP160t1" */
     923,    /* "brainpoolP192r1" */
     924,    /* "brainpoolP192t1" */
     925,    /* "brainpoolP224r1" */
     926,    /* "brainpoolP224t1" */
     927,    /* "brainpoolP256r1" */
     928,    /* "brainpoolP256t1" */
     929,    /* "brainpoolP320r1" */
     930,    /* "brainpoolP320t1" */
     931,    /* "brainpoolP384r1" */
     932,    /* "brainpoolP384t1" */
     933,    /* "brainpoolP512r1" */
     934,    /* "brainpoolP512t1" */
     494,    /* "buildingName" */
     860,    /* "businessCategory" */
     691,    /* "c2onb191v4" */
     692,    /* "c2onb191v5" */
     697,    /* "c2onb239v4" */
     698,    /* "c2onb239v5" */
     684,    /* "c2pnb163v1" */
     685,    /* "c2pnb163v2" */
     686,    /* "c2pnb163v3" */
     687,    /* "c2pnb176v1" */
     693,    /* "c2pnb208w1" */
     699,    /* "c2pnb272w1" */
     700,    /* "c2pnb304w1" */
     702,    /* "c2pnb368w1" */
     688,    /* "c2tnb191v1" */
     689,    /* "c2tnb191v2" */
     690,    /* "c2tnb191v3" */
     694,    /* "c2tnb239v1" */
     695,    /* "c2tnb239v2" */
     696,    /* "c2tnb239v3" */
     701,    /* "c2tnb359v1" */
     703,    /* "c2tnb431r1" */
     881,    /* "cACertificate" */
     483,    /* "cNAMERecord" */
     751,    /* "camellia-128-cbc" */
     962,    /* "camellia-128-ccm" */
     757,    /* "camellia-128-cfb" */
     760,    /* "camellia-128-cfb1" */
     763,    /* "camellia-128-cfb8" */
     964,    /* "camellia-128-cmac" */
     963,    /* "camellia-128-ctr" */
     754,    /* "camellia-128-ecb" */
     961,    /* "camellia-128-gcm" */
     766,    /* "camellia-128-ofb" */
     752,    /* "camellia-192-cbc" */
     966,    /* "camellia-192-ccm" */
     758,    /* "camellia-192-cfb" */
     761,    /* "camellia-192-cfb1" */
     764,    /* "camellia-192-cfb8" */
     968,    /* "camellia-192-cmac" */
     967,    /* "camellia-192-ctr" */
     755,    /* "camellia-192-ecb" */
     965,    /* "camellia-192-gcm" */
     767,    /* "camellia-192-ofb" */
     753,    /* "camellia-256-cbc" */
     970,    /* "camellia-256-ccm" */
     759,    /* "camellia-256-cfb" */
     762,    /* "camellia-256-cfb1" */
     765,    /* "camellia-256-cfb8" */
     972,    /* "camellia-256-cmac" */
     971,    /* "camellia-256-ctr" */
     756,    /* "camellia-256-ecb" */
     969,    /* "camellia-256-gcm" */
     768,    /* "camellia-256-ofb" */
     443,    /* "caseIgnoreIA5StringSyntax" */
     108,    /* "cast5-cbc" */
     110,    /* "cast5-cfb" */
     109,    /* "cast5-ecb" */
     111,    /* "cast5-ofb" */
     152,    /* "certBag" */
     677,    /* "certicom-arc" */
     517,    /* "certificate extensions" */
     883,    /* "certificateRevocationList" */
    1019,    /* "chacha20" */
    1018,    /* "chacha20-poly1305" */
      54,    /* "challengePassword" */
     407,    /* "characteristic-two-field" */
     395,    /* "clearance" */
     633,    /* "cleartext track 2" */
     894,    /* "cmac" */
      13,    /* "commonName" */
     513,    /* "content types" */
      50,    /* "contentType" */
      53,    /* "countersignature" */
    1090,    /* "countryCode3c" */
    1091,    /* "countryCode3n" */
      14,    /* "countryName" */
     153,    /* "crlBag" */
     884,    /* "crossCertificatePair" */
     806,    /* "cryptocom" */
     805,    /* "cryptopro" */
     500,    /* "dITRedirect" */
     451,    /* "dNSDomain" */
     495,    /* "dSAQuality" */
     434,    /* "data" */
     390,    /* "dcObject" */
     891,    /* "deltaRevocationList" */
      31,    /* "des-cbc" */
     643,    /* "des-cdmf" */
      30,    /* "des-cfb" */
     656,    /* "des-cfb1" */
     657,    /* "des-cfb8" */
      29,    /* "des-ecb" */
      32,    /* "des-ede" */
      43,    /* "des-ede-cbc" */
      60,    /* "des-ede-cfb" */
      62,    /* "des-ede-ofb" */
      33,    /* "des-ede3" */
      44,    /* "des-ede3-cbc" */
      61,    /* "des-ede3-cfb" */
     658,    /* "des-ede3-cfb1" */
     659,    /* "des-ede3-cfb8" */
      63,    /* "des-ede3-ofb" */
      45,    /* "des-ofb" */
     107,    /* "description" */
     871,    /* "destinationIndicator" */
      80,    /* "desx-cbc" */
     947,    /* "dh-cofactor-kdf" */
     946,    /* "dh-std-kdf" */
      28,    /* "dhKeyAgreement" */
     941,    /* "dhSinglePass-cofactorDH-sha1kdf-scheme" */
     942,    /* "dhSinglePass-cofactorDH-sha224kdf-scheme" */
     943,    /* "dhSinglePass-cofactorDH-sha256kdf-scheme" */
     944,    /* "dhSinglePass-cofactorDH-sha384kdf-scheme" */
     945,    /* "dhSinglePass-cofactorDH-sha512kdf-scheme" */
     936,    /* "dhSinglePass-stdDH-sha1kdf-scheme" */
     937,    /* "dhSinglePass-stdDH-sha224kdf-scheme" */
     938,    /* "dhSinglePass-stdDH-sha256kdf-scheme" */
     939,    /* "dhSinglePass-stdDH-sha384kdf-scheme" */
     940,    /* "dhSinglePass-stdDH-sha512kdf-scheme" */
      11,    /* "directory services (X.500)" */
     378,    /* "directory services - algorithms" */
     887,    /* "distinguishedName" */
     892,    /* "dmdName" */
     174,    /* "dnQualifier" */
    1092,    /* "dnsName" */
     447,    /* "document" */
     471,    /* "documentAuthor" */
     468,    /* "documentIdentifier" */
     472,    /* "documentLocation" */
     502,    /* "documentPublisher" */
     449,    /* "documentSeries" */
     469,    /* "documentTitle" */
     470,    /* "documentVersion" */
     380,    /* "dod" */
     391,    /* "domainComponent" */
     452,    /* "domainRelatedObject" */
     116,    /* "dsaEncryption" */
      67,    /* "dsaEncryption-old" */
      66,    /* "dsaWithSHA" */
     113,    /* "dsaWithSHA1" */
      70,    /* "dsaWithSHA1-old" */
     802,    /* "dsa_with_SHA224" */
     803,    /* "dsa_with_SHA256" */
    1108,    /* "dsa_with_SHA3-224" */
    1109,    /* "dsa_with_SHA3-256" */
    1110,    /* "dsa_with_SHA3-384" */
    1111,    /* "dsa_with_SHA3-512" */
    1106,    /* "dsa_with_SHA384" */
    1107,    /* "dsa_with_SHA512" */
     297,    /* "dvcs" */
     791,    /* "ecdsa-with-Recommended" */
     416,    /* "ecdsa-with-SHA1" */
     793,    /* "ecdsa-with-SHA224" */
     794,    /* "ecdsa-with-SHA256" */
     795,    /* "ecdsa-with-SHA384" */
     796,    /* "ecdsa-with-SHA512" */
     792,    /* "ecdsa-with-Specified" */
    1112,    /* "ecdsa_with_SHA3-224" */
    1113,    /* "ecdsa_with_SHA3-256" */
    1114,    /* "ecdsa_with_SHA3-384" */
    1115,    /* "ecdsa_with_SHA3-512" */
      48,    /* "emailAddress" */
     632,    /* "encrypted track 2" */
     885,    /* "enhancedSearchGuide" */
      56,    /* "extendedCertificateAttributes" */
     867,    /* "facsimileTelephoneNumber" */
     462,    /* "favouriteDrink" */
    1126,    /* "ffdhe2048" */
    1127,    /* "ffdhe3072" */
    1128,    /* "ffdhe4096" */
    1129,    /* "ffdhe6144" */
    1130,    /* "ffdhe8192" */
     453,    /* "friendlyCountry" */
     490,    /* "friendlyCountryName" */
     156,    /* "friendlyName" */
     631,    /* "generate cryptogram" */
     509,    /* "generationQualifier" */
     601,    /* "generic cryptogram" */
      99,    /* "givenName" */
     976,    /* "gost-mac-12" */
    1009,    /* "gost89-cbc" */
     814,    /* "gost89-cnt" */
     975,    /* "gost89-cnt-12" */
    1011,    /* "gost89-ctr" */
    1010,    /* "gost89-ecb" */
    1015,    /* "grasshopper-cbc" */
    1016,    /* "grasshopper-cfb" */
    1013,    /* "grasshopper-ctr" */
    1012,    /* "grasshopper-ecb" */
    1017,    /* "grasshopper-mac" */
    1014,    /* "grasshopper-ofb" */
    1036,    /* "hkdf" */
     855,    /* "hmac" */
     780,    /* "hmac-md5" */
     781,    /* "hmac-sha1" */
    1102,    /* "hmac-sha3-224" */
    1103,    /* "hmac-sha3-256" */
    1104,    /* "hmac-sha3-384" */
    1105,    /* "hmac-sha3-512" */
     797,    /* "hmacWithMD5" */
     163,    /* "hmacWithSHA1" */
     798,    /* "hmacWithSHA224" */
     799,    /* "hmacWithSHA256" */
     800,    /* "hmacWithSHA384" */
     801,    /* "hmacWithSHA512" */
    1193,    /* "hmacWithSHA512-224" */
    1194,    /* "hmacWithSHA512-256" */
     486,    /* "homePostalAddress" */
     473,    /* "homeTelephoneNumber" */
     466,    /* "host" */
     889,    /* "houseIdentifier" */
     442,    /* "iA5StringSyntax" */
     381,    /* "iana" */
     824,    /* "id-Gost28147-89-CryptoPro-A-ParamSet" */
     825,    /* "id-Gost28147-89-CryptoPro-B-ParamSet" */
     826,    /* "id-Gost28147-89-CryptoPro-C-ParamSet" */
     827,    /* "id-Gost28147-89-CryptoPro-D-ParamSet" */
     819,    /* "id-Gost28147-89-CryptoPro-KeyMeshing" */
     829,    /* "id-Gost28147-89-CryptoPro-Oscar-1-0-ParamSet" */
     828,    /* "id-Gost28147-89-CryptoPro-Oscar-1-1-ParamSet" */
     830,    /* "id-Gost28147-89-CryptoPro-RIC-1-ParamSet" */
     820,    /* "id-Gost28147-89-None-KeyMeshing" */
     823,    /* "id-Gost28147-89-TestParamSet" */
     840,    /* "id-GostR3410-2001-CryptoPro-A-ParamSet" */
     841,    /* "id-GostR3410-2001-CryptoPro-B-ParamSet" */
     842,    /* "id-GostR3410-2001-CryptoPro-C-ParamSet" */
     843,    /* "id-GostR3410-2001-CryptoPro-XchA-ParamSet" */
     844,    /* "id-GostR3410-2001-CryptoPro-XchB-ParamSet" */
     839,    /* "id-GostR3410-2001-TestParamSet" */
     832,    /* "id-GostR3410-94-CryptoPro-A-ParamSet" */
     833,    /* "id-GostR3410-94-CryptoPro-B-ParamSet" */
     834,    /* "id-GostR3410-94-CryptoPro-C-ParamSet" */
     835,    /* "id-GostR3410-94-CryptoPro-D-ParamSet" */
     836,    /* "id-GostR3410-94-CryptoPro-XchA-ParamSet" */
     837,    /* "id-GostR3410-94-CryptoPro-XchB-ParamSet" */
     838,    /* "id-GostR3410-94-CryptoPro-XchC-ParamSet" */
     831,    /* "id-GostR3410-94-TestParamSet" */
     845,    /* "id-GostR3410-94-a" */
     846,    /* "id-GostR3410-94-aBis" */
     847,    /* "id-GostR3410-94-b" */
     848,    /* "id-GostR3410-94-bBis" */
     822,    /* "id-GostR3411-94-CryptoProParamSet" */
     821,    /* "id-GostR3411-94-TestParamSet" */
     266,    /* "id-aca" */
     355,    /* "id-aca-accessIdentity" */
     354,    /* "id-aca-authenticationInfo" */
     356,    /* "id-aca-chargingIdentity" */
     399,    /* "id-aca-encAttrs" */
     357,    /* "id-aca-group" */
     358,    /* "id-aca-role" */
     176,    /* "id-ad" */
     788,    /* "id-aes128-wrap" */
     897,    /* "id-aes128-wrap-pad" */
     789,    /* "id-aes192-wrap" */
     900,    /* "id-aes192-wrap-pad" */
     790,    /* "id-aes256-wrap" */
     903,    /* "id-aes256-wrap-pad" */
     262,    /* "id-alg" */
     893,    /* "id-alg-PWRI-KEK" */
     323,    /* "id-alg-des40" */
     326,    /* "id-alg-dh-pop" */
     325,    /* "id-alg-dh-sig-hmac-sha1" */
     324,    /* "id-alg-noSignature" */
     907,    /* "id-camellia128-wrap" */
     908,    /* "id-camellia192-wrap" */
     909,    /* "id-camellia256-wrap" */
     268,    /* "id-cct" */
     361,    /* "id-cct-PKIData" */
     362,    /* "id-cct-PKIResponse" */
     360,    /* "id-cct-crs" */
      81,    /* "id-ce" */
     680,    /* "id-characteristic-two-basis" */
     263,    /* "id-cmc" */
     334,    /* "id-cmc-addExtensions" */
     346,    /* "id-cmc-confirmCertAcceptance" */
     330,    /* "id-cmc-dataReturn" */
     336,    /* "id-cmc-decryptedPOP" */
     335,    /* "id-cmc-encryptedPOP" */
     339,    /* "id-cmc-getCRL" */
     338,    /* "id-cmc-getCert" */
     328,    /* "id-cmc-identification" */
     329,    /* "id-cmc-identityProof" */
     337,    /* "id-cmc-lraPOPWitness" */
     344,    /* "id-cmc-popLinkRandom" */
     345,    /* "id-cmc-popLinkWitness" */
     343,    /* "id-cmc-queryPending" */
     333,    /* "id-cmc-recipientNonce" */
     341,    /* "id-cmc-regInfo" */
     342,    /* "id-cmc-responseInfo" */
     340,    /* "id-cmc-revokeRequest" */
     332,    /* "id-cmc-senderNonce" */
     327,    /* "id-cmc-statusInfo" */
     331,    /* "id-cmc-transactionId" */
     787,    /* "id-ct-asciiTextWithCRLF" */
    1060,    /* "id-ct-xml" */
     408,    /* "id-ecPublicKey" */
     508,    /* "id-hex-multipart-message" */
     507,    /* "id-hex-partial-message" */
     260,    /* "id-it" */
     302,    /* "id-it-caKeyUpdateInfo" */
     298,    /* "id-it-caProtEncCert" */
     311,    /* "id-it-confirmWaitTime" */
     303,    /* "id-it-currentCRL" */
     300,    /* "id-it-encKeyPairTypes" */
     310,    /* "id-it-implicitConfirm" */
     308,    /* "id-it-keyPairParamRep" */
     307,    /* "id-it-keyPairParamReq" */
     312,    /* "id-it-origPKIMessage" */
     301,    /* "id-it-preferredSymmAlg" */
     309,    /* "id-it-revPassphrase" */
     299,    /* "id-it-signKeyPairTypes" */
     305,    /* "id-it-subscriptionRequest" */
     306,    /* "id-it-subscriptionResponse" */
     784,    /* "id-it-suppLangTags" */
     304,    /* "id-it-unsupportedOIDs" */
     128,    /* "id-kp" */
     280,    /* "id-mod-attribute-cert" */
     274,    /* "id-mod-cmc" */
     277,    /* "id-mod-cmp" */
     284,    /* "id-mod-cmp2000" */
     273,    /* "id-mod-crmf" */
     283,    /* "id-mod-dvcs" */
     275,    /* "id-mod-kea-profile-88" */
     276,    /* "id-mod-kea-profile-93" */
     282,    /* "id-mod-ocsp" */
     278,    /* "id-mod-qualified-cert-88" */
     279,    /* "id-mod-qualified-cert-93" */
     281,    /* "id-mod-timestamp-protocol" */
     264,    /* "id-on" */
     347,    /* "id-on-personalData" */
     265,    /* "id-pda" */
     352,    /* "id-pda-countryOfCitizenship" */
     353,    /* "id-pda-countryOfResidence" */
     348,    /* "id-pda-dateOfBirth" */
     351,    /* "id-pda-gender" */
     349,    /* "id-pda-placeOfBirth" */
     175,    /* "id-pe" */
    1031,    /* "id-pkinit" */
     261,    /* "id-pkip" */
     258,    /* "id-pkix-mod" */
     269,    /* "id-pkix1-explicit-88" */
     271,    /* "id-pkix1-explicit-93" */
     270,    /* "id-pkix1-implicit-88" */
     272,    /* "id-pkix1-implicit-93" */
     662,    /* "id-ppl" */
     267,    /* "id-qcs" */
     359,    /* "id-qcs-pkixQCSyntax-v1" */
     259,    /* "id-qt" */
     313,    /* "id-regCtrl" */
     316,    /* "id-regCtrl-authenticator" */
     319,    /* "id-regCtrl-oldCertID" */
     318,    /* "id-regCtrl-pkiArchiveOptions" */
     317,    /* "id-regCtrl-pkiPublicationInfo" */
     320,    /* "id-regCtrl-protocolEncrKey" */
     315,    /* "id-regCtrl-regToken" */
     314,    /* "id-regInfo" */
     322,    /* "id-regInfo-certReq" */
     321,    /* "id-regInfo-utf8Pairs" */
     191,    /* "id-smime-aa" */
     215,    /* "id-smime-aa-contentHint" */
     218,    /* "id-smime-aa-contentIdentifier" */
     221,    /* "id-smime-aa-contentReference" */
     240,    /* "id-smime-aa-dvcs-dvc" */
     217,    /* "id-smime-aa-encapContentType" */
     222,    /* "id-smime-aa-encrypKeyPref" */
     220,    /* "id-smime-aa-equivalentLabels" */
     232,    /* "id-smime-aa-ets-CertificateRefs" */
     233,    /* "id-smime-aa-ets-RevocationRefs" */
     238,    /* "id-smime-aa-ets-archiveTimeStamp" */
     237,    /* "id-smime-aa-ets-certCRLTimestamp" */
     234,    /* "id-smime-aa-ets-certValues" */
     227,    /* "id-smime-aa-ets-commitmentType" */
     231,    /* "id-smime-aa-ets-contentTimestamp" */
     236,    /* "id-smime-aa-ets-escTimeStamp" */
     230,    /* "id-smime-aa-ets-otherSigCert" */
     235,    /* "id-smime-aa-ets-revocationValues" */
     226,    /* "id-smime-aa-ets-sigPolicyId" */
     229,    /* "id-smime-aa-ets-signerAttr" */
     228,    /* "id-smime-aa-ets-signerLocation" */
     219,    /* "id-smime-aa-macValue" */
     214,    /* "id-smime-aa-mlExpandHistory" */
     216,    /* "id-smime-aa-msgSigDigest" */
     212,    /* "id-smime-aa-receiptRequest" */
     213,    /* "id-smime-aa-securityLabel" */
     239,    /* "id-smime-aa-signatureType" */
     223,    /* "id-smime-aa-signingCertificate" */
    1086,    /* "id-smime-aa-signingCertificateV2" */
     224,    /* "id-smime-aa-smimeEncryptCerts" */
     225,    /* "id-smime-aa-timeStampToken" */
     192,    /* "id-smime-alg" */
     243,    /* "id-smime-alg-3DESwrap" */
     246,    /* "id-smime-alg-CMS3DESwrap" */
     247,    /* "id-smime-alg-CMSRC2wrap" */
     245,    /* "id-smime-alg-ESDH" */
     241,    /* "id-smime-alg-ESDHwith3DES" */
     242,    /* "id-smime-alg-ESDHwithRC2" */
     244,    /* "id-smime-alg-RC2wrap" */
     193,    /* "id-smime-cd" */
     248,    /* "id-smime-cd-ldap" */
     190,    /* "id-smime-ct" */
     210,    /* "id-smime-ct-DVCSRequestData" */
     211,    /* "id-smime-ct-DVCSResponseData" */
     208,    /* "id-smime-ct-TDTInfo" */
     207,    /* "id-smime-ct-TSTInfo" */
     205,    /* "id-smime-ct-authData" */
    1059,    /* "id-smime-ct-authEnvelopedData" */
     786,    /* "id-smime-ct-compressedData" */
    1058,    /* "id-smime-ct-contentCollection" */
     209,    /* "id-smime-ct-contentInfo" */
     206,    /* "id-smime-ct-publishCert" */
     204,    /* "id-smime-ct-receipt" */
     195,    /* "id-smime-cti" */
     255,    /* "id-smime-cti-ets-proofOfApproval" */
     256,    /* "id-smime-cti-ets-proofOfCreation" */
     253,    /* "id-smime-cti-ets-proofOfDelivery" */
     251,    /* "id-smime-cti-ets-proofOfOrigin" */
     252,    /* "id-smime-cti-ets-proofOfReceipt" */
     254,    /* "id-smime-cti-ets-proofOfSender" */
     189,    /* "id-smime-mod" */
     196,    /* "id-smime-mod-cms" */
     197,    /* "id-smime-mod-ess" */
     202,    /* "id-smime-mod-ets-eSigPolicy-88" */
     203,    /* "id-smime-mod-ets-eSigPolicy-97" */
     200,    /* "id-smime-mod-ets-eSignature-88" */
     201,    /* "id-smime-mod-ets-eSignature-97" */
     199,    /* "id-smime-mod-msg-v3" */
     198,    /* "id-smime-mod-oid" */
     194,    /* "id-smime-spq" */
     250,    /* "id-smime-spq-ets-sqt-unotice" */
     249,    /* "id-smime-spq-ets-sqt-uri" */
     974,    /* "id-tc26" */
     991,    /* "id-tc26-agreement" */
     992,    /* "id-tc26-agreement-gost-3410-2012-256" */
     993,    /* "id-tc26-agreement-gost-3410-2012-512" */
     977,    /* "id-tc26-algorithms" */
     990,    /* "id-tc26-cipher" */
    1001,    /* "id-tc26-cipher-constants" */
    1176,    /* "id-tc26-cipher-gostr3412-2015-kuznyechik" */
    1177,    /* "id-tc26-cipher-gostr3412-2015-kuznyechik-ctracpkm" */
    1178,    /* "id-tc26-cipher-gostr3412-2015-kuznyechik-ctracpkm-omac" */
    1173,    /* "id-tc26-cipher-gostr3412-2015-magma" */
    1174,    /* "id-tc26-cipher-gostr3412-2015-magma-ctracpkm" */
    1175,    /* "id-tc26-cipher-gostr3412-2015-magma-ctracpkm-omac" */
     994,    /* "id-tc26-constants" */
     981,    /* "id-tc26-digest" */
    1000,    /* "id-tc26-digest-constants" */
    1002,    /* "id-tc26-gost-28147-constants" */
    1147,    /* "id-tc26-gost-3410-2012-256-constants" */
     996,    /* "id-tc26-gost-3410-2012-512-constants" */
     987,    /* "id-tc26-mac" */
     978,    /* "id-tc26-sign" */
     995,    /* "id-tc26-sign-constants" */
     984,    /* "id-tc26-signwithdigest" */
    1179,    /* "id-tc26-wrap" */
    1182,    /* "id-tc26-wrap-gostr3412-2015-kuznyechik" */
    1183,    /* "id-tc26-wrap-gostr3412-2015-kuznyechik-kexp15" */
    1180,    /* "id-tc26-wrap-gostr3412-2015-magma" */
    1181,    /* "id-tc26-wrap-gostr3412-2015-magma-kexp15" */
      34,    /* "idea-cbc" */
      35,    /* "idea-cfb" */
      36,    /* "idea-ecb" */
      46,    /* "idea-ofb" */
     676,    /* "identified-organization" */
    1170,    /* "ieee" */
     461,    /* "info" */
     101,    /* "initials" */
     869,    /* "internationaliSDNNumber" */
    1022,    /* "ipsec Internet Key Exchange" */
     749,    /* "ipsec3" */
     750,    /* "ipsec4" */
     181,    /* "iso" */
     623,    /* "issuer capabilities" */
     645,    /* "itu-t" */
     492,    /* "janetMailbox" */
     646,    /* "joint-iso-itu-t" */
     957,    /* "jurisdictionCountryName" */
     955,    /* "jurisdictionLocalityName" */
     956,    /* "jurisdictionStateOrProvinceName" */
     150,    /* "keyBag" */
     773,    /* "kisa" */
    1063,    /* "kx-any" */
    1039,    /* "kx-dhe" */
    1041,    /* "kx-dhe-psk" */
    1038,    /* "kx-ecdhe" */
    1040,    /* "kx-ecdhe-psk" */
    1045,    /* "kx-gost" */
    1043,    /* "kx-psk" */
    1037,    /* "kx-rsa" */
    1042,    /* "kx-rsa-psk" */
    1044,    /* "kx-srp" */
     477,    /* "lastModifiedBy" */
     476,    /* "lastModifiedTime" */
     157,    /* "localKeyID" */
      15,    /* "localityName" */
     480,    /* "mXRecord" */
    1190,    /* "magma-cbc" */
    1191,    /* "magma-cfb" */
    1188,    /* "magma-ctr" */
    1187,    /* "magma-ecb" */
    1192,    /* "magma-mac" */
    1189,    /* "magma-ofb" */
     493,    /* "mailPreferenceOption" */
     467,    /* "manager" */
       3,    /* "md2" */
       7,    /* "md2WithRSAEncryption" */
     257,    /* "md4" */
     396,    /* "md4WithRSAEncryption" */
       4,    /* "md5" */
     114,    /* "md5-sha1" */
     104,    /* "md5WithRSA" */
       8,    /* "md5WithRSAEncryption" */
      95,    /* "mdc2" */
      96,    /* "mdc2WithRSA" */
     875,    /* "member" */
     602,    /* "merchant initiated auth" */
     514,    /* "message extensions" */
      51,    /* "messageDigest" */
     911,    /* "mgf1" */
     506,    /* "mime-mhs-bodies" */
     505,    /* "mime-mhs-headings" */
     488,    /* "mobileTelephoneNumber" */
     481,    /* "nSRecord" */
     173,    /* "name" */
     681,    /* "onBasis" */
     379,    /* "org" */
    1089,    /* "organizationIdentifier" */
      17,    /* "organizationName" */
     491,    /* "organizationalStatus" */
      18,    /* "organizationalUnitName" */
    1141,    /* "oscca" */
     475,    /* "otherMailbox" */
     876,    /* "owner" */
     935,    /* "pSpecified" */
     489,    /* "pagerTelephoneNumber" */
     782,    /* "password based MAC" */
     374,    /* "path" */
     621,    /* "payment gateway capabilities" */
       9,    /* "pbeWithMD2AndDES-CBC" */
     168,    /* "pbeWithMD2AndRC2-CBC" */
     112,    /* "pbeWithMD5AndCast5CBC" */
      10,    /* "pbeWithMD5AndDES-CBC" */
     169,    /* "pbeWithMD5AndRC2-CBC" */
     148,    /* "pbeWithSHA1And128BitRC2-CBC" */
     144,    /* "pbeWithSHA1And128BitRC4" */
     147,    /* "pbeWithSHA1And2-KeyTripleDES-CBC" */
     146,    /* "pbeWithSHA1And3-KeyTripleDES-CBC" */
     149,    /* "pbeWithSHA1And40BitRC2-CBC" */
     145,    /* "pbeWithSHA1And40BitRC4" */
     170,    /* "pbeWithSHA1AndDES-CBC" */
      68,    /* "pbeWithSHA1AndRC2-CBC" */
     499,    /* "personalSignature" */
     487,    /* "personalTitle" */
     464,    /* "photo" */
     863,    /* "physicalDeliveryOfficeName" */
     437,    /* "pilot" */
     439,    /* "pilotAttributeSyntax" */
     438,    /* "pilotAttributeType" */
     479,    /* "pilotAttributeType27" */
     456,    /* "pilotDSA" */
     441,    /* "pilotGroups" */
     444,    /* "pilotObject" */
     440,    /* "pilotObjectClass" */
     455,    /* "pilotOrganization" */
     445,    /* "pilotPerson" */
     186,    /* "pkcs1" */
      27,    /* "pkcs3" */
     187,    /* "pkcs5" */
      20,    /* "pkcs7" */
      21,    /* "pkcs7-data" */
      25,    /* "pkcs7-digestData" */
      26,    /* "pkcs7-encryptedData" */
      23,    /* "pkcs7-envelopedData" */
      24,    /* "pkcs7-signedAndEnvelopedData" */
      22,    /* "pkcs7-signedData" */
     151,    /* "pkcs8ShroudedKeyBag" */
      47,    /* "pkcs9" */
    1061,    /* "poly1305" */
     862,    /* "postOfficeBox" */
     861,    /* "postalAddress" */
     661,    /* "postalCode" */
     683,    /* "ppBasis" */
     872,    /* "preferredDeliveryMethod" */
     873,    /* "presentationAddress" */
     406,    /* "prime-field" */
     409,    /* "prime192v1" */
     410,    /* "prime192v2" */
     411,    /* "prime192v3" */
     412,    /* "prime239v1" */
     413,    /* "prime239v2" */
     414,    /* "prime239v3" */
     415,    /* "prime256v1" */
     886,    /* "protocolInformation" */
     510,    /* "pseudonym" */
     435,    /* "pss" */
     286,    /* "qcStatements" */
     457,    /* "qualityLabelledData" */
     450,    /* "rFC822localPart" */
      98,    /* "rc2-40-cbc" */
     166,    /* "rc2-64-cbc" */
      37,    /* "rc2-cbc" */
      39,    /* "rc2-cfb" */
      38,    /* "rc2-ecb" */
      40,    /* "rc2-ofb" */
       5,    /* "rc4" */
      97,    /* "rc4-40" */
     915,    /* "rc4-hmac-md5" */
     120,    /* "rc5-cbc" */
     122,    /* "rc5-cfb" */
     121,    /* "rc5-ecb" */
     123,    /* "rc5-ofb" */
     870,    /* "registeredAddress" */
     460,    /* "rfc822Mailbox" */
     117,    /* "ripemd160" */
     119,    /* "ripemd160WithRSA" */
     400,    /* "role" */
     877,    /* "roleOccupant" */
     448,    /* "room" */
     463,    /* "roomNumber" */
      19,    /* "rsa" */
       6,    /* "rsaEncryption" */
     644,    /* "rsaOAEPEncryptionSET" */
     377,    /* "rsaSignature" */
     919,    /* "rsaesOaep" */
     912,    /* "rsassaPss" */
     482,    /* "sOARecord" */
     155,    /* "safeContentsBag" */
     291,    /* "sbgp-autonomousSysNum" */
     290,    /* "sbgp-ipAddrBlock" */
     292,    /* "sbgp-routerIdentifier" */
     973,    /* "scrypt" */
     159,    /* "sdsiCertificate" */
     859,    /* "searchGuide" */
     704,    /* "secp112r1" */
     705,    /* "secp112r2" */
     706,    /* "secp128r1" */
     707,    /* "secp128r2" */
     708,    /* "secp160k1" */
     709,    /* "secp160r1" */
     710,    /* "secp160r2" */
     711,    /* "secp192k1" */
     712,    /* "secp224k1" */
     713,    /* "secp224r1" */
     714,    /* "secp256k1" */
     715,    /* "secp384r1" */
     716,    /* "secp521r1" */
     154,    /* "secretBag" */
     474,    /* "secretary" */
     717,    /* "sect113r1" */
     718,    /* "sect113r2" */
     719,    /* "sect131r1" */
     720,    /* "sect131r2" */
     721,    /* "sect163k1" */
     722,    /* "sect163r1" */
     723,    /* "sect163r2" */
     724,    /* "sect193r1" */
     725,    /* "sect193r2" */
     726,    /* "sect233k1" */
     727,    /* "sect233r1" */
     728,    /* "sect239k1" */
     729,    /* "sect283k1" */
     730,    /* "sect283r1" */
     731,    /* "sect409k1" */
     732,    /* "sect409r1" */
     733,    /* "sect571k1" */
     734,    /* "sect571r1" */
     635,    /* "secure device signature" */
     878,    /* "seeAlso" */
     777,    /* "seed-cbc" */
     779,    /* "seed-cfb" */
     776,    /* "seed-ecb" */
     778,    /* "seed-ofb" */
     105,    /* "serialNumber" */
     625,    /* "set-addPolicy" */
     515,    /* "set-attr" */
     518,    /* "set-brand" */
     638,    /* "set-brand-AmericanExpress" */
     637,    /* "set-brand-Diners" */
     636,    /* "set-brand-IATA-ATA" */
     639,    /* "set-brand-JCB" */
     641,    /* "set-brand-MasterCard" */
     642,    /* "set-brand-Novus" */
     640,    /* "set-brand-Visa" */
     516,    /* "set-policy" */
     607,    /* "set-policy-root" */
     624,    /* "set-rootKeyThumb" */
     620,    /* "setAttr-Cert" */
     628,    /* "setAttr-IssCap-CVM" */
     630,    /* "setAttr-IssCap-Sig" */
     629,    /* "setAttr-IssCap-T2" */
     627,    /* "setAttr-Token-B0Prime" */
     626,    /* "setAttr-Token-EMV" */
     622,    /* "setAttr-TokenType" */
     619,    /* "setCext-IssuerCapabilities" */
     615,    /* "setCext-PGWYcapabilities" */
     616,    /* "setCext-TokenIdentifier" */
     618,    /* "setCext-TokenType" */
     617,    /* "setCext-Track2Data" */
     611,    /* "setCext-cCertRequired" */
     609,    /* "setCext-certType" */
     608,    /* "setCext-hashedRoot" */
     610,    /* "setCext-merchData" */
     613,    /* "setCext-setExt" */
     614,    /* "setCext-setQualf" */
     612,    /* "setCext-tunneling" */
     540,    /* "setct-AcqCardCodeMsg" */
     576,    /* "setct-AcqCardCodeMsgTBE" */
     570,    /* "setct-AuthReqTBE" */
     534,    /* "setct-AuthReqTBS" */
     527,    /* "setct-AuthResBaggage" */
     571,    /* "setct-AuthResTBE" */
     572,    /* "setct-AuthResTBEX" */
     535,    /* "setct-AuthResTBS" */
     536,    /* "setct-AuthResTBSX" */
     528,    /* "setct-AuthRevReqBaggage" */
     577,    /* "setct-AuthRevReqTBE" */
     541,    /* "setct-AuthRevReqTBS" */
     529,    /* "setct-AuthRevResBaggage" */
     542,    /* "setct-AuthRevResData" */
     578,    /* "setct-AuthRevResTBE" */
     579,    /* "setct-AuthRevResTBEB" */
     543,    /* "setct-AuthRevResTBS" */
     573,    /* "setct-AuthTokenTBE" */
     537,    /* "setct-AuthTokenTBS" */
     600,    /* "setct-BCIDistributionTBS" */
     558,    /* "setct-BatchAdminReqData" */
     592,    /* "setct-BatchAdminReqTBE" */
     559,    /* "setct-BatchAdminResData" */
     593,    /* "setct-BatchAdminResTBE" */
     599,    /* "setct-CRLNotificationResTBS" */
     598,    /* "setct-CRLNotificationTBS" */
     580,    /* "setct-CapReqTBE" */
     581,    /* "setct-CapReqTBEX" */
     544,    /* "setct-CapReqTBS" */
     545,    /* "setct-CapReqTBSX" */
     546,    /* "setct-CapResData" */
     582,    /* "setct-CapResTBE" */
     583,    /* "setct-CapRevReqTBE" */
     584,    /* "setct-CapRevReqTBEX" */
     547,    /* "setct-CapRevReqTBS" */
     548,    /* "setct-CapRevReqTBSX" */
     549,    /* "setct-CapRevResData" */
     585,    /* "setct-CapRevResTBE" */
     538,    /* "setct-CapTokenData" */
     530,    /* "setct-CapTokenSeq" */
     574,    /* "setct-CapTokenTBE" */
     575,    /* "setct-CapTokenTBEX" */
     539,    /* "setct-CapTokenTBS" */
     560,    /* "setct-CardCInitResTBS" */
     566,    /* "setct-CertInqReqTBS" */
     563,    /* "setct-CertReqData" */
     595,    /* "setct-CertReqTBE" */
     596,    /* "setct-CertReqTBEX" */
     564,    /* "setct-CertReqTBS" */
     565,    /* "setct-CertResData" */
     597,    /* "setct-CertResTBE" */
     586,    /* "setct-CredReqTBE" */
     587,    /* "setct-CredReqTBEX" */
     550,    /* "setct-CredReqTBS" */
     551,    /* "setct-CredReqTBSX" */
     552,    /* "setct-CredResData" */
     588,    /* "setct-CredResTBE" */
     589,    /* "setct-CredRevReqTBE" */
     590,    /* "setct-CredRevReqTBEX" */
     553,    /* "setct-CredRevReqTBS" */
     554,    /* "setct-CredRevReqTBSX" */
     555,    /* "setct-CredRevResData" */
     591,    /* "setct-CredRevResTBE" */
     567,    /* "setct-ErrorTBS" */
     526,    /* "setct-HODInput" */
     561,    /* "setct-MeAqCInitResTBS" */
     522,    /* "setct-OIData" */
     519,    /* "setct-PANData" */
     521,    /* "setct-PANOnly" */
     520,    /* "setct-PANToken" */
     556,    /* "setct-PCertReqData" */
     557,    /* "setct-PCertResTBS" */
     523,    /* "setct-PI" */
     532,    /* "setct-PI-TBS" */
     524,    /* "setct-PIData" */
     525,    /* "setct-PIDataUnsigned" */
     568,    /* "setct-PIDualSignedTBE" */
     569,    /* "setct-PIUnsignedTBE" */
     531,    /* "setct-PInitResData" */
     533,    /* "setct-PResData" */
     594,    /* "setct-RegFormReqTBE" */
     562,    /* "setct-RegFormResTBS" */
     604,    /* "setext-pinAny" */
     603,    /* "setext-pinSecure" */
     605,    /* "setext-track2" */
      41,    /* "sha" */
      64,    /* "sha1" */
     115,    /* "sha1WithRSA" */
      65,    /* "sha1WithRSAEncryption" */
     675,    /* "sha224" */
     671,    /* "sha224WithRSAEncryption" */
     672,    /* "sha256" */
     668,    /* "sha256WithRSAEncryption" */
    1096,    /* "sha3-224" */
    1097,    /* "sha3-256" */
    1098,    /* "sha3-384" */
    1099,    /* "sha3-512" */
     673,    /* "sha384" */
     669,    /* "sha384WithRSAEncryption" */
     674,    /* "sha512" */
    1094,    /* "sha512-224" */
    1145,    /* "sha512-224WithRSAEncryption" */
    1095,    /* "sha512-256" */
    1146,    /* "sha512-256WithRSAEncryption" */
     670,    /* "sha512WithRSAEncryption" */
      42,    /* "shaWithRSAEncryption" */
    1100,    /* "shake128" */
    1101,    /* "shake256" */
      52,    /* "signingTime" */
     454,    /* "simpleSecurityObject" */
     496,    /* "singleLevelQuality" */
    1062,    /* "siphash" */
    1142,    /* "sm-scheme" */
    1172,    /* "sm2" */
    1143,    /* "sm3" */
    1144,    /* "sm3WithRSAEncryption" */
    1134,    /* "sm4-cbc" */
    1137,    /* "sm4-cfb" */
    1136,    /* "sm4-cfb1" */
    1138,    /* "sm4-cfb8" */
    1139,    /* "sm4-ctr" */
    1133,    /* "sm4-ecb" */
    1135,    /* "sm4-ofb" */
      16,    /* "stateOrProvinceName" */
     660,    /* "streetAddress" */
     498,    /* "subtreeMaximumQuality" */
     497,    /* "subtreeMinimumQuality" */
     890,    /* "supportedAlgorithms" */
     874,    /* "supportedApplicationContext" */
     100,    /* "surname" */
     864,    /* "telephoneNumber" */
     866,    /* "teletexTerminalIdentifier" */
     865,    /* "telexNumber" */
     459,    /* "textEncodedORAddress" */
     293,    /* "textNotice" */
     106,    /* "title" */
    1021,    /* "tls1-prf" */
     682,    /* "tpBasis" */
    1151,    /* "ua-pki" */
     436,    /* "ucl" */
       0,    /* "undefined" */
     102,    /* "uniqueIdentifier" */
     888,    /* "uniqueMember" */
      55,    /* "unstructuredAddress" */
      49,    /* "unstructuredName" */
     880,    /* "userCertificate" */
     465,    /* "userClass" */
     458,    /* "userId" */
     879,    /* "userPassword" */
     373,    /* "valid" */
     678,    /* "wap" */
     679,    /* "wap-wsg" */
     735,    /* "wap-wsg-idm-ecid-wtls1" */
     743,    /* "wap-wsg-idm-ecid-wtls10" */
     744,    /* "wap-wsg-idm-ecid-wtls11" */
     745,    /* "wap-wsg-idm-ecid-wtls12" */
     736,    /* "wap-wsg-idm-ecid-wtls3" */
     737,    /* "wap-wsg-idm-ecid-wtls4" */
     738,    /* "wap-wsg-idm-ecid-wtls5" */
     739,    /* "wap-wsg-idm-ecid-wtls6" */
     740,    /* "wap-wsg-idm-ecid-wtls7" */
     741,    /* "wap-wsg-idm-ecid-wtls8" */
     742,    /* "wap-wsg-idm-ecid-wtls9" */
     804,    /* "whirlpool" */
     868,    /* "x121Address" */
     503,    /* "x500UniqueIdentifier" */
     158,    /* "x509Certificate" */
     160,    /* "x509Crl" */
     125,    /* "zlib compression" */
};

#define NUM_OBJ 1071
static const unsigned int obj_objs[NUM_OBJ] = {
       0,    /* OBJ_undef                        0 */
     181,    /* OBJ_iso                          1 */
     393,    /* OBJ_joint_iso_ccitt              OBJ_joint_iso_itu_t */
     404,    /* OBJ_ccitt                        OBJ_itu_t */
     645,    /* OBJ_itu_t                        0 */
     646,    /* OBJ_joint_iso_itu_t              2 */
     434,    /* OBJ_data                         0 9 */
     182,    /* OBJ_member_body                  1 2 */
     379,    /* OBJ_org                          1 3 */
     676,    /* OBJ_identified_organization      1 3 */
      11,    /* OBJ_X500                         2 5 */
     647,    /* OBJ_international_organizations  2 23 */
     380,    /* OBJ_dod                          1 3 6 */
    1170,    /* OBJ_ieee                         1 3 111 */
      12,    /* OBJ_X509                         2 5 4 */
     378,    /* OBJ_X500algorithms               2 5 8 */
      81,    /* OBJ_id_ce                        2 5 29 */
     512,    /* OBJ_id_set                       2 23 42 */
     678,    /* OBJ_wap                          2 23 43 */
     435,    /* OBJ_pss                          0 9 2342 */
    1140,    /* OBJ_ISO_CN                       1 2 156 */
    1150,    /* OBJ_ISO_UA                       1 2 804 */
     183,    /* OBJ_ISO_US                       1 2 840 */
     381,    /* OBJ_iana                         1 3 6 1 */
    1034,    /* OBJ_X25519                       1 3 101 110 */
    1035,    /* OBJ_X448                         1 3 101 111 */
    1087,    /* OBJ_ED25519                      1 3 101 112 */
    1088,    /* OBJ_ED448                        1 3 101 113 */
     677,    /* OBJ_certicom_arc                 1 3 132 */
     394,    /* OBJ_selected_attribute_types     2 5 1 5 */
      13,    /* OBJ_commonName                   2 5 4 3 */
     100,    /* OBJ_surname                      2 5 4 4 */
     105,    /* OBJ_serialNumber                 2 5 4 5 */
      14,    /* OBJ_countryName                  2 5 4 6 */
      15,    /* OBJ_localityName                 2 5 4 7 */
      16,    /* OBJ_stateOrProvinceName          2 5 4 8 */
     660,    /* OBJ_streetAddress                2 5 4 9 */
      17,    /* OBJ_organizationName             2 5 4 10 */
      18,    /* OBJ_organizationalUnitName       2 5 4 11 */
     106,    /* OBJ_title                        2 5 4 12 */
     107,    /* OBJ_description                  2 5 4 13 */
     859,    /* OBJ_searchGuide                  2 5 4 14 */
     860,    /* OBJ_businessCategory             2 5 4 15 */
     861,    /* OBJ_postalAddress                2 5 4 16 */
     661,    /* OBJ_postalCode                   2 5 4 17 */
     862,    /* OBJ_postOfficeBox                2 5 4 18 */
     863,    /* OBJ_physicalDeliveryOfficeName   2 5 4 19 */
     864,    /* OBJ_telephoneNumber              2 5 4 20 */
     865,    /* OBJ_telexNumber                  2 5 4 21 */
     866,    /* OBJ_teletexTerminalIdentifier    2 5 4 22 */
     867,    /* OBJ_facsimileTelephoneNumber     2 5 4 23 */
     868,    /* OBJ_x121Address                  2 5 4 24 */
     869,    /* OBJ_internationaliSDNNumber      2 5 4 25 */
     870,    /* OBJ_registeredAddress            2 5 4 26 */
     871,    /* OBJ_destinationIndicator         2 5 4 27 */
     872,    /* OBJ_preferredDeliveryMethod      2 5 4 28 */
     873,    /* OBJ_presentationAddress          2 5 4 29 */
     874,    /* OBJ_supportedApplicationContext  2 5 4 30 */
     875,    /* OBJ_member                       2 5 4 31 */
     876,    /* OBJ_owner                        2 5 4 32 */
     877,    /* OBJ_roleOccupant                 2 5 4 33 */
     878,    /* OBJ_seeAlso                      2 5 4 34 */
     879,    /* OBJ_userPassword                 2 5 4 35 */
     880,    /* OBJ_userCertificate              2 5 4 36 */
     881,    /* OBJ_cACertificate                2 5 4 37 */
     882,    /* OBJ_authorityRevocationList      2 5 4 38 */
     883,    /* OBJ_certificateRevocationList    2 5 4 39 */
     884,    /* OBJ_crossCertificatePair         2 5 4 40 */
     173,    /* OBJ_name                         2 5 4 41 */
      99,    /* OBJ_givenName                    2 5 4 42 */
     101,    /* OBJ_initials                     2 5 4 43 */
     509,    /* OBJ_generationQualifier          2 5 4 44 */
     503,    /* OBJ_x500UniqueIdentifier         2 5 4 45 */
     174,    /* OBJ_dnQualifier                  2 5 4 46 */
     885,    /* OBJ_enhancedSearchGuide          2 5 4 47 */
     886,    /* OBJ_protocolInformation          2 5 4 48 */
     887,    /* OBJ_distinguishedName            2 5 4 49 */
     888,    /* OBJ_uniqueMember                 2 5 4 50 */
     889,    /* OBJ_houseIdentifier              2 5 4 51 */
     890,    /* OBJ_supportedAlgorithms          2 5 4 52 */
     891,    /* OBJ_deltaRevocationList          2 5 4 53 */
     892,    /* OBJ_dmdName                      2 5 4 54 */
     510,    /* OBJ_pseudonym                    2 5 4 65 */
     400,    /* OBJ_role                         2 5 4 72 */
    1089,    /* OBJ_organizationIdentifier       2 5 4 97 */
    1090,    /* OBJ_countryCode3c                2 5 4 98 */
    1091,    /* OBJ_countryCode3n                2 5 4 99 */
    1092,    /* OBJ_dnsName                      2 5 4 100 */
     769,    /* OBJ_subject_directory_attributes 2 5 29 9 */
      82,    /* OBJ_subject_key_identifier       2 5 29 14 */
      83,    /* OBJ_key_usage                    2 5 29 15 */
      84,    /* OBJ_private_key_usage_period     2 5 29 16 */
      85,    /* OBJ_subject_alt_name             2 5 29 17 */
      86,    /* OBJ_issuer_alt_name              2 5 29 18 */
      87,    /* OBJ_basic_constraints            2 5 29 19 */
      88,    /* OBJ_crl_number                   2 5 29 20 */
     141,    /* OBJ_crl_reason                   2 5 29 21 */
     430,    /* OBJ_hold_instruction_code        2 5 29 23 */
     142,    /* OBJ_invalidity_date              2 5 29 24 */
     140,    /* OBJ_delta_crl                    2 5 29 27 */
     770,    /* OBJ_issuing_distribution_point   2 5 29 28 */
     771,    /* OBJ_certificate_issuer           2 5 29 29 */
     666,    /* OBJ_name_constraints             2 5 29 30 */
     103,    /* OBJ_crl_distribution_points      2 5 29 31 */
      89,    /* OBJ_certificate_policies         2 5 29 32 */
     747,    /* OBJ_policy_mappings              2 5 29 33 */
      90,    /* OBJ_authority_key_identifier     2 5 29 35 */
     401,    /* OBJ_policy_constraints           2 5 29 36 */
     126,    /* OBJ_ext_key_usage                2 5 29 37 */
     857,    /* OBJ_freshest_crl                 2 5 29 46 */
     748,    /* OBJ_inhibit_any_policy           2 5 29 54 */
     402,    /* OBJ_target_information           2 5 29 55 */
     403,    /* OBJ_no_rev_avail                 2 5 29 56 */
     513,    /* OBJ_set_ctype                    2 23 42 0 */
     514,    /* OBJ_set_msgExt                   2 23 42 1 */
     515,    /* OBJ_set_attr                     2 23 42 3 */
     516,    /* OBJ_set_policy                   2 23 42 5 */
     517,    /* OBJ_set_certExt                  2 23 42 7 */
     518,    /* OBJ_set_brand                    2 23 42 8 */
     679,    /* OBJ_wap_wsg                      2 23 43 1 */
     382,    /* OBJ_Directory                    1 3 6 1 1 */
     383,    /* OBJ_Management                   1 3 6 1 2 */
     384,    /* OBJ_Experimental                 1 3 6 1 3 */
     385,    /* OBJ_Private                      1 3 6 1 4 */
     386,    /* OBJ_Security                     1 3 6 1 5 */
     387,    /* OBJ_SNMPv2                       1 3 6 1 6 */
     388,    /* OBJ_Mail                         1 3 6 1 7 */
     376,    /* OBJ_algorithm                    1 3 14 3 2 */
     395,    /* OBJ_clearance                    2 5 1 5 55 */
      19,    /* OBJ_rsa                          2 5 8 1 1 */
      96,    /* OBJ_mdc2WithRSA                  2 5 8 3 100 */
      95,    /* OBJ_mdc2                         2 5 8 3 101 */
     746,    /* OBJ_any_policy                   2 5 29 32 0 */
     910,    /* OBJ_anyExtendedKeyUsage          2 5 29 37 0 */
     519,    /* OBJ_setct_PANData                2 23 42 0 0 */
     520,    /* OBJ_setct_PANToken               2 23 42 0 1 */
     521,    /* OBJ_setct_PANOnly                2 23 42 0 2 */
     522,    /* OBJ_setct_OIData                 2 23 42 0 3 */
     523,    /* OBJ_setct_PI                     2 23 42 0 4 */
     524,    /* OBJ_setct_PIData                 2 23 42 0 5 */
     525,    /* OBJ_setct_PIDataUnsigned         2 23 42 0 6 */
     526,    /* OBJ_setct_HODInput               2 23 42 0 7 */
     527,    /* OBJ_setct_AuthResBaggage         2 23 42 0 8 */
     528,    /* OBJ_setct_AuthRevReqBaggage      2 23 42 0 9 */
     529,    /* OBJ_setct_AuthRevResBaggage      2 23 42 0 10 */
     530,    /* OBJ_setct_CapTokenSeq            2 23 42 0 11 */
     531,    /* OBJ_setct_PInitResData           2 23 42 0 12 */
     532,    /* OBJ_setct_PI_TBS                 2 23 42 0 13 */
     533,    /* OBJ_setct_PResData               2 23 42 0 14 */
     534,    /* OBJ_setct_AuthReqTBS             2 23 42 0 16 */
     535,    /* OBJ_setct_AuthResTBS             2 23 42 0 17 */
     536,    /* OBJ_setct_AuthResTBSX            2 23 42 0 18 */
     537,    /* OBJ_setct_AuthTokenTBS           2 23 42 0 19 */
     538,    /* OBJ_setct_CapTokenData           2 23 42 0 20 */
     539,    /* OBJ_setct_CapTokenTBS            2 23 42 0 21 */
     540,    /* OBJ_setct_AcqCardCodeMsg         2 23 42 0 22 */
     541,    /* OBJ_setct_AuthRevReqTBS          2 23 42 0 23 */
     542,    /* OBJ_setct_AuthRevResData         2 23 42 0 24 */
     543,    /* OBJ_setct_AuthRevResTBS          2 23 42 0 25 */
     544,    /* OBJ_setct_CapReqTBS              2 23 42 0 26 */
     545,    /* OBJ_setct_CapReqTBSX             2 23 42 0 27 */
     546,    /* OBJ_setct_CapResData             2 23 42 0 28 */
     547,    /* OBJ_setct_CapRevReqTBS           2 23 42 0 29 */
     548,    /* OBJ_setct_CapRevReqTBSX          2 23 42 0 30 */
     549,    /* OBJ_setct_CapRevResData          2 23 42 0 31 */
     550,    /* OBJ_setct_CredReqTBS             2 23 42 0 32 */
     551,    /* OBJ_setct_CredReqTBSX            2 23 42 0 33 */
     552,    /* OBJ_setct_CredResData            2 23 42 0 34 */
     553,    /* OBJ_setct_CredRevReqTBS          2 23 42 0 35 */
     554,    /* OBJ_setct_CredRevReqTBSX         2 23 42 0 36 */
     555,    /* OBJ_setct_CredRevResData         2 23 42 0 37 */
     556,    /* OBJ_setct_PCertReqData           2 23 42 0 38 */
     557,    /* OBJ_setct_PCertResTBS            2 23 42 0 39 */
     558,    /* OBJ_setct_BatchAdminReqData      2 23 42 0 40 */
     559,    /* OBJ_setct_BatchAdminResData      2 23 42 0 41 */
     560,    /* OBJ_setct_CardCInitResTBS        2 23 42 0 42 */
     561,    /* OBJ_setct_MeAqCInitResTBS        2 23 42 0 43 */
     562,    /* OBJ_setct_RegFormResTBS          2 23 42 0 44 */
     563,    /* OBJ_setct_CertReqData            2 23 42 0 45 */
     564,    /* OBJ_setct_CertReqTBS             2 23 42 0 46 */
     565,    /* OBJ_setct_CertResData            2 23 42 0 47 */
     566,    /* OBJ_setct_CertInqReqTBS          2 23 42 0 48 */
     567,    /* OBJ_setct_ErrorTBS               2 23 42 0 49 */
     568,    /* OBJ_setct_PIDualSignedTBE        2 23 42 0 50 */
     569,    /* OBJ_setct_PIUnsignedTBE          2 23 42 0 51 */
     570,    /* OBJ_setct_AuthReqTBE             2 23 42 0 52 */
     571,    /* OBJ_setct_AuthResTBE             2 23 42 0 53 */
     572,    /* OBJ_setct_AuthResTBEX            2 23 42 0 54 */
     573,    /* OBJ_setct_AuthTokenTBE           2 23 42 0 55 */
     574,    /* OBJ_setct_CapTokenTBE            2 23 42 0 56 */
     575,    /* OBJ_setct_CapTokenTBEX           2 23 42 0 57 */
     576,    /* OBJ_setct_AcqCardCodeMsgTBE      2 23 42 0 58 */
     577,    /* OBJ_setct_AuthRevReqTBE          2 23 42 0 59 */
     578,    /* OBJ_setct_AuthRevResTBE          2 23 42 0 60 */
     579,    /* OBJ_setct_AuthRevResTBEB         2 23 42 0 61 */
     580,    /* OBJ_setct_CapReqTBE              2 23 42 0 62 */
     581,    /* OBJ_setct_CapReqTBEX             2 23 42 0 63 */
     582,    /* OBJ_setct_CapResTBE              2 23 42 0 64 */
     583,    /* OBJ_setct_CapRevReqTBE           2 23 42 0 65 */
     584,    /* OBJ_setct_CapRevReqTBEX          2 23 42 0 66 */
     585,    /* OBJ_setct_CapRevResTBE           2 23 42 0 67 */
     586,    /* OBJ_setct_CredReqTBE             2 23 42 0 68 */
     587,    /* OBJ_setct_CredReqTBEX            2 23 42 0 69 */
     588,    /* OBJ_setct_CredResTBE             2 23 42 0 70 */
     589,    /* OBJ_setct_CredRevReqTBE          2 23 42 0 71 */
     590,    /* OBJ_setct_CredRevReqTBEX         2 23 42 0 72 */
     591,    /* OBJ_setct_CredRevResTBE          2 23 42 0 73 */
     592,    /* OBJ_setct_BatchAdminReqTBE       2 23 42 0 74 */
     593,    /* OBJ_setct_BatchAdminResTBE       2 23 42 0 75 */
     594,    /* OBJ_setct_RegFormReqTBE          2 23 42 0 76 */
     595,    /* OBJ_setct_CertReqTBE             2 23 42 0 77 */
     596,    /* OBJ_setct_CertReqTBEX            2 23 42 0 78 */
     597,    /* OBJ_setct_CertResTBE             2 23 42 0 79 */
     598,    /* OBJ_setct_CRLNotificationTBS     2 23 42 0 80 */
     599,    /* OBJ_setct_CRLNotificationResTBS  2 23 42 0 81 */
     600,    /* OBJ_setct_BCIDistributionTBS     2 23 42 0 82 */
     601,    /* OBJ_setext_genCrypt              2 23 42 1 1 */
     602,    /* OBJ_setext_miAuth                2 23 42 1 3 */
     603,    /* OBJ_setext_pinSecure             2 23 42 1 4 */
     604,    /* OBJ_setext_pinAny                2 23 42 1 5 */
     605,    /* OBJ_setext_track2                2 23 42 1 7 */
     606,    /* OBJ_setext_cv                    2 23 42 1 8 */
     620,    /* OBJ_setAttr_Cert                 2 23 42 3 0 */
     621,    /* OBJ_setAttr_PGWYcap              2 23 42 3 1 */
     622,    /* OBJ_setAttr_TokenType            2 23 42 3 2 */
     623,    /* OBJ_setAttr_IssCap               2 23 42 3 3 */
     607,    /* OBJ_set_policy_root              2 23 42 5 0 */
     608,    /* OBJ_setCext_hashedRoot           2 23 42 7 0 */
     609,    /* OBJ_setCext_certType             2 23 42 7 1 */
     610,    /* OBJ_setCext_merchData            2 23 42 7 2 */
     611,    /* OBJ_setCext_cCertRequired        2 23 42 7 3 */
     612,    /* OBJ_setCext_tunneling            2 23 42 7 4 */
     613,    /* OBJ_setCext_setExt               2 23 42 7 5 */
     614,    /* OBJ_setCext_setQualf             2 23 42 7 6 */
     615,    /* OBJ_setCext_PGWYcapabilities     2 23 42 7 7 */
     616,    /* OBJ_setCext_TokenIdentifier      2 23 42 7 8 */
     617,    /* OBJ_setCext_Track2Data           2 23 42 7 9 */
     618,    /* OBJ_setCext_TokenType            2 23 42 7 10 */
     619,    /* OBJ_setCext_IssuerCapabilities   2 23 42 7 11 */
     636,    /* OBJ_set_brand_IATA_ATA           2 23 42 8 1 */
     640,    /* OBJ_set_brand_Visa               2 23 42 8 4 */
     641,    /* OBJ_set_brand_MasterCard         2 23 42 8 5 */
     637,    /* OBJ_set_brand_Diners             2 23 42 8 30 */
     638,    /* OBJ_set_brand_AmericanExpress    2 23 42 8 34 */
     639,    /* OBJ_set_brand_JCB                2 23 42 8 35 */
    1141,    /* OBJ_oscca                        1 2 156 10197 */
     805,    /* OBJ_cryptopro                    1 2 643 2 2 */
     806,    /* OBJ_cryptocom                    1 2 643 2 9 */
     974,    /* OBJ_id_tc26                      1 2 643 7 1 */
    1005,    /* OBJ_OGRN                         1 2 643 100 1 */
    1006,    /* OBJ_SNILS                        1 2 643 100 3 */
    1007,    /* OBJ_subjectSignTool              1 2 643 100 111 */
    1008,    /* OBJ_issuerSignTool               1 2 643 100 112 */
     184,    /* OBJ_X9_57                        1 2 840 10040 */
     405,    /* OBJ_ansi_X9_62                   1 2 840 10045 */
     389,    /* OBJ_Enterprises                  1 3 6 1 4 1 */
     504,    /* OBJ_mime_mhs                     1 3 6 1 7 1 */
     104,    /* OBJ_md5WithRSA                   1 3 14 3 2 3 */
      29,    /* OBJ_des_ecb                      1 3 14 3 2 6 */
      31,    /* OBJ_des_cbc                      1 3 14 3 2 7 */
      45,    /* OBJ_des_ofb64                    1 3 14 3 2 8 */
      30,    /* OBJ_des_cfb64                    1 3 14 3 2 9 */
     377,    /* OBJ_rsaSignature                 1 3 14 3 2 11 */
      67,    /* OBJ_dsa_2                        1 3 14 3 2 12 */
      66,    /* OBJ_dsaWithSHA                   1 3 14 3 2 13 */
      42,    /* OBJ_shaWithRSAEncryption         1 3 14 3 2 15 */
      32,    /* OBJ_des_ede_ecb                  1 3 14 3 2 17 */
      41,    /* OBJ_sha                          1 3 14 3 2 18 */
      64,    /* OBJ_sha1                         1 3 14 3 2 26 */
      70,    /* OBJ_dsaWithSHA1_2                1 3 14 3 2 27 */
     115,    /* OBJ_sha1WithRSA                  1 3 14 3 2 29 */
     117,    /* OBJ_ripemd160                    1 3 36 3 2 1 */
    1093,    /* OBJ_x509ExtAdmission             1 3 36 8 3 3 */
     143,    /* OBJ_sxnet                        1 3 101 1 4 1 */
    1171,    /* OBJ_ieee_siswg                   1 3 111 2 1619 */
     721,    /* OBJ_sect163k1                    1 3 132 0 1 */
     722,    /* OBJ_sect163r1                    1 3 132 0 2 */
     728,    /* OBJ_sect239k1                    1 3 132 0 3 */
     717,    /* OBJ_sect113r1                    1 3 132 0 4 */
     718,    /* OBJ_sect113r2                    1 3 132 0 5 */
     704,    /* OBJ_secp112r1                    1 3 132 0 6 */
     705,    /* OBJ_secp112r2                    1 3 132 0 7 */
     709,    /* OBJ_secp160r1                    1 3 132 0 8 */
     708,    /* OBJ_secp160k1                    1 3 132 0 9 */
     714,    /* OBJ_secp256k1                    1 3 132 0 10 */
     723,    /* OBJ_sect163r2                    1 3 132 0 15 */
     729,    /* OBJ_sect283k1                    1 3 132 0 16 */
     730,    /* OBJ_sect283r1                    1 3 132 0 17 */
     719,    /* OBJ_sect131r1                    1 3 132 0 22 */
     720,    /* OBJ_sect131r2                    1 3 132 0 23 */
     724,    /* OBJ_sect193r1                    1 3 132 0 24 */
     725,    /* OBJ_sect193r2                    1 3 132 0 25 */
     726,    /* OBJ_sect233k1                    1 3 132 0 26 */
     727,    /* OBJ_sect233r1                    1 3 132 0 27 */
     706,    /* OBJ_secp128r1                    1 3 132 0 28 */
     707,    /* OBJ_secp128r2                    1 3 132 0 29 */
     710,    /* OBJ_secp160r2                    1 3 132 0 30 */
     711,    /* OBJ_secp192k1                    1 3 132 0 31 */
     712,    /* OBJ_secp224k1                    1 3 132 0 32 */
     713,    /* OBJ_secp224r1                    1 3 132 0 33 */
     715,    /* OBJ_secp384r1                    1 3 132 0 34 */
     716,    /* OBJ_secp521r1                    1 3 132 0 35 */
     731,    /* OBJ_sect409k1                    1 3 132 0 36 */
     732,    /* OBJ_sect409r1                    1 3 132 0 37 */
     733,    /* OBJ_sect571k1                    1 3 132 0 38 */
     734,    /* OBJ_sect571r1                    1 3 132 0 39 */
     624,    /* OBJ_set_rootKeyThumb             2 23 42 3 0 0 */
     625,    /* OBJ_set_addPolicy                2 23 42 3 0 1 */
     626,    /* OBJ_setAttr_Token_EMV            2 23 42 3 2 1 */
     627,    /* OBJ_setAttr_Token_B0Prime        2 23 42 3 2 2 */
     628,    /* OBJ_setAttr_IssCap_CVM           2 23 42 3 3 3 */
     629,    /* OBJ_setAttr_IssCap_T2            2 23 42 3 3 4 */
     630,    /* OBJ_setAttr_IssCap_Sig           2 23 42 3 3 5 */
     642,    /* OBJ_set_brand_Novus              2 23 42 8 6011 */
     735,    /* OBJ_wap_wsg_idm_ecid_wtls1       2 23 43 1 4 1 */
     736,    /* OBJ_wap_wsg_idm_ecid_wtls3       2 23 43 1 4 3 */
     737,    /* OBJ_wap_wsg_idm_ecid_wtls4       2 23 43 1 4 4 */
     738,    /* OBJ_wap_wsg_idm_ecid_wtls5       2 23 43 1 4 5 */
     739,    /* OBJ_wap_wsg_idm_ecid_wtls6       2 23 43 1 4 6 */
     740,    /* OBJ_wap_wsg_idm_ecid_wtls7       2 23 43 1 4 7 */
     741,    /* OBJ_wap_wsg_idm_ecid_wtls8       2 23 43 1 4 8 */
     742,    /* OBJ_wap_wsg_idm_ecid_wtls9       2 23 43 1 4 9 */
     743,    /* OBJ_wap_wsg_idm_ecid_wtls10      2 23 43 1 4 10 */
     744,    /* OBJ_wap_wsg_idm_ecid_wtls11      2 23 43 1 4 11 */
     745,    /* OBJ_wap_wsg_idm_ecid_wtls12      2 23 43 1 4 12 */
     804,    /* OBJ_whirlpool                    1 0 10118 3 0 55 */
    1142,    /* OBJ_sm_scheme                    1 2 156 10197 1 */
     773,    /* OBJ_kisa                         1 2 410 200004 */
     807,    /* OBJ_id_GostR3411_94_with_GostR3410_2001 1 2 643 2 2 3 */
     808,    /* OBJ_id_GostR3411_94_with_GostR3410_94 1 2 643 2 2 4 */
     809,    /* OBJ_id_GostR3411_94              1 2 643 2 2 9 */
     810,    /* OBJ_id_HMACGostR3411_94          1 2 643 2 2 10 */
     811,    /* OBJ_id_GostR3410_2001            1 2 643 2 2 19 */
     812,    /* OBJ_id_GostR3410_94              1 2 643 2 2 20 */
     813,    /* OBJ_id_Gost28147_89              1 2 643 2 2 21 */
     815,    /* OBJ_id_Gost28147_89_MAC          1 2 643 2 2 22 */
     816,    /* OBJ_id_GostR3411_94_prf          1 2 643 2 2 23 */
     817,    /* OBJ_id_GostR3410_2001DH          1 2 643 2 2 98 */
     818,    /* OBJ_id_GostR3410_94DH            1 2 643 2 2 99 */
     977,    /* OBJ_id_tc26_algorithms           1 2 643 7 1 1 */
     994,    /* OBJ_id_tc26_constants            1 2 643 7 1 2 */
       1,    /* OBJ_rsadsi                       1 2 840 113549 */
     185,    /* OBJ_X9cm                         1 2 840 10040 4 */
    1031,    /* OBJ_id_pkinit                    1 3 6 1 5 2 3 */
     127,    /* OBJ_id_pkix                      1 3 6 1 5 5 7 */
     505,    /* OBJ_mime_mhs_headings            1 3 6 1 7 1 1 */
     506,    /* OBJ_mime_mhs_bodies              1 3 6 1 7 1 2 */
     119,    /* OBJ_ripemd160WithRSA             1 3 36 3 3 1 2 */
     937,    /* OBJ_dhSinglePass_stdDH_sha224kdf_scheme 1 3 132 1 11 0 */
     938,    /* OBJ_dhSinglePass_stdDH_sha256kdf_scheme 1 3 132 1 11 1 */
     939,    /* OBJ_dhSinglePass_stdDH_sha384kdf_scheme 1 3 132 1 11 2 */
     940,    /* OBJ_dhSinglePass_stdDH_sha512kdf_scheme 1 3 132 1 11 3 */
     942,    /* OBJ_dhSinglePass_cofactorDH_sha224kdf_scheme 1 3 132 1 14 0 */
     943,    /* OBJ_dhSinglePass_cofactorDH_sha256kdf_scheme 1 3 132 1 14 1 */
     944,    /* OBJ_dhSinglePass_cofactorDH_sha384kdf_scheme 1 3 132 1 14 2 */
     945,    /* OBJ_dhSinglePass_cofactorDH_sha512kdf_scheme 1 3 132 1 14 3 */
     631,    /* OBJ_setAttr_GenCryptgrm          2 23 42 3 3 3 1 */
     632,    /* OBJ_setAttr_T2Enc                2 23 42 3 3 4 1 */
     633,    /* OBJ_setAttr_T2cleartxt           2 23 42 3 3 4 2 */
     634,    /* OBJ_setAttr_TokICCsig            2 23 42 3 3 5 1 */
     635,    /* OBJ_setAttr_SecDevSig            2 23 42 3 3 5 2 */
     436,    /* OBJ_ucl                          0 9 2342 19200300 */
     820,    /* OBJ_id_Gost28147_89_None_KeyMeshing 1 2 643 2 2 14 0 */
     819,    /* OBJ_id_Gost28147_89_CryptoPro_KeyMeshing 1 2 643 2 2 14 1 */
     845,    /* OBJ_id_GostR3410_94_a            1 2 643 2 2 20 1 */
     846,    /* OBJ_id_GostR3410_94_aBis         1 2 643 2 2 20 2 */
     847,    /* OBJ_id_GostR3410_94_b            1 2 643 2 2 20 3 */
     848,    /* OBJ_id_GostR3410_94_bBis         1 2 643 2 2 20 4 */
     821,    /* OBJ_id_GostR3411_94_TestParamSet 1 2 643 2 2 30 0 */
     822,    /* OBJ_id_GostR3411_94_CryptoProParamSet 1 2 643 2 2 30 1 */
     823,    /* OBJ_id_Gost28147_89_TestParamSet 1 2 643 2 2 31 0 */
     824,    /* OBJ_id_Gost28147_89_CryptoPro_A_ParamSet 1 2 643 2 2 31 1 */
     825,    /* OBJ_id_Gost28147_89_CryptoPro_B_ParamSet 1 2 643 2 2 31 2 */
     826,    /* OBJ_id_Gost28147_89_CryptoPro_C_ParamSet 1 2 643 2 2 31 3 */
     827,    /* OBJ_id_Gost28147_89_CryptoPro_D_ParamSet 1 2 643 2 2 31 4 */
     828,    /* OBJ_id_Gost28147_89_CryptoPro_Oscar_1_1_ParamSet 1 2 643 2 2 31 5 */
     829,    /* OBJ_id_Gost28147_89_CryptoPro_Oscar_1_0_ParamSet 1 2 643 2 2 31 6 */
     830,    /* OBJ_id_Gost28147_89_CryptoPro_RIC_1_ParamSet 1 2 643 2 2 31 7 */
     831,    /* OBJ_id_GostR3410_94_TestParamSet 1 2 643 2 2 32 0 */
     832,    /* OBJ_id_GostR3410_94_CryptoPro_A_ParamSet 1 2 643 2 2 32 2 */
     833,    /* OBJ_id_GostR3410_94_CryptoPro_B_ParamSet 1 2 643 2 2 32 3 */
     834,    /* OBJ_id_GostR3410_94_CryptoPro_C_ParamSet 1 2 643 2 2 32 4 */
     835,    /* OBJ_id_GostR3410_94_CryptoPro_D_ParamSet 1 2 643 2 2 32 5 */
     836,    /* OBJ_id_GostR3410_94_CryptoPro_XchA_ParamSet 1 2 643 2 2 33 1 */
     837,    /* OBJ_id_GostR3410_94_CryptoPro_XchB_ParamSet 1 2 643 2 2 33 2 */
     838,    /* OBJ_id_GostR3410_94_CryptoPro_XchC_ParamSet 1 2 643 2 2 33 3 */
     839,    /* OBJ_id_GostR3410_2001_TestParamSet 1 2 643 2 2 35 0 */
     840,    /* OBJ_id_GostR3410_2001_CryptoPro_A_ParamSet 1 2 643 2 2 35 1 */
     841,    /* OBJ_id_GostR3410_2001_CryptoPro_B_ParamSet 1 2 643 2 2 35 2 */
     842,    /* OBJ_id_GostR3410_2001_CryptoPro_C_ParamSet 1 2 643 2 2 35 3 */
     843,    /* OBJ_id_GostR3410_2001_CryptoPro_XchA_ParamSet 1 2 643 2 2 36 0 */
     844,    /* OBJ_id_GostR3410_2001_CryptoPro_XchB_ParamSet 1 2 643 2 2 36 1 */
     978,    /* OBJ_id_tc26_sign                 1 2 643 7 1 1 1 */
     981,    /* OBJ_id_tc26_digest               1 2 643 7 1 1 2 */
     984,    /* OBJ_id_tc26_signwithdigest       1 2 643 7 1 1 3 */
     987,    /* OBJ_id_tc26_mac                  1 2 643 7 1 1 4 */
     990,    /* OBJ_id_tc26_cipher               1 2 643 7 1 1 5 */
     991,    /* OBJ_id_tc26_agreement            1 2 643 7 1 1 6 */
    1179,    /* OBJ_id_tc26_wrap                 1 2 643 7 1 1 7 */
     995,    /* OBJ_id_tc26_sign_constants       1 2 643 7 1 2 1 */
    1000,    /* OBJ_id_tc26_digest_constants     1 2 643 7 1 2 2 */
    1001,    /* OBJ_id_tc26_cipher_constants     1 2 643 7 1 2 5 */
    1151,    /* OBJ_ua_pki                       1 2 804 2 1 1 1 */
       2,    /* OBJ_pkcs                         1 2 840 113549 1 */
     431,    /* OBJ_hold_instruction_none        1 2 840 10040 2 1 */
     432,    /* OBJ_hold_instruction_call_issuer 1 2 840 10040 2 2 */
     433,    /* OBJ_hold_instruction_reject      1 2 840 10040 2 3 */
     116,    /* OBJ_dsa                          1 2 840 10040 4 1 */
     113,    /* OBJ_dsaWithSHA1                  1 2 840 10040 4 3 */
     406,    /* OBJ_X9_62_prime_field            1 2 840 10045 1 1 */
     407,    /* OBJ_X9_62_characteristic_two_field 1 2 840 10045 1 2 */
     408,    /* OBJ_X9_62_id_ecPublicKey         1 2 840 10045 2 1 */
     416,    /* OBJ_ecdsa_with_SHA1              1 2 840 10045 4 1 */
     791,    /* OBJ_ecdsa_with_Recommended       1 2 840 10045 4 2 */
     792,    /* OBJ_ecdsa_with_Specified         1 2 840 10045 4 3 */
     920,    /* OBJ_dhpublicnumber               1 2 840 10046 2 1 */
    1032,    /* OBJ_pkInitClientAuth             1 3 6 1 5 2 3 4 */
    1033,    /* OBJ_pkInitKDC                    1 3 6 1 5 2 3 5 */
     258,    /* OBJ_id_pkix_mod                  1 3 6 1 5 5 7 0 */
     175,    /* OBJ_id_pe                        1 3 6 1 5 5 7 1 */
     259,    /* OBJ_id_qt                        1 3 6 1 5 5 7 2 */
     128,    /* OBJ_id_kp                        1 3 6 1 5 5 7 3 */
     260,    /* OBJ_id_it                        1 3 6 1 5 5 7 4 */
     261,    /* OBJ_id_pkip                      1 3 6 1 5 5 7 5 */
     262,    /* OBJ_id_alg                       1 3 6 1 5 5 7 6 */
     263,    /* OBJ_id_cmc                       1 3 6 1 5 5 7 7 */
     264,    /* OBJ_id_on                        1 3 6 1 5 5 7 8 */
     265,    /* OBJ_id_pda                       1 3 6 1 5 5 7 9 */
     266,    /* OBJ_id_aca                       1 3 6 1 5 5 7 10 */
     267,    /* OBJ_id_qcs                       1 3 6 1 5 5 7 11 */
     268,    /* OBJ_id_cct                       1 3 6 1 5 5 7 12 */
     662,    /* OBJ_id_ppl                       1 3 6 1 5 5 7 21 */
     176,    /* OBJ_id_ad                        1 3 6 1 5 5 7 48 */
     507,    /* OBJ_id_hex_partial_message       1 3 6 1 7 1 1 1 */
     508,    /* OBJ_id_hex_multipart_message     1 3 6 1 7 1 1 2 */
      57,    /* OBJ_netscape                     2 16 840 1 113730 */
     754,    /* OBJ_camellia_128_ecb             0 3 4401 5 3 1 9 1 */
     766,    /* OBJ_camellia_128_ofb128          0 3 4401 5 3 1 9 3 */
     757,    /* OBJ_camellia_128_cfb128          0 3 4401 5 3 1 9 4 */
     961,    /* OBJ_camellia_128_gcm             0 3 4401 5 3 1 9 6 */
     962,    /* OBJ_camellia_128_ccm             0 3 4401 5 3 1 9 7 */
     963,    /* OBJ_camellia_128_ctr             0 3 4401 5 3 1 9 9 */
     964,    /* OBJ_camellia_128_cmac            0 3 4401 5 3 1 9 10 */
     755,    /* OBJ_camellia_192_ecb             0 3 4401 5 3 1 9 21 */
     767,    /* OBJ_camellia_192_ofb128          0 3 4401 5 3 1 9 23 */
     758,    /* OBJ_camellia_192_cfb128          0 3 4401 5 3 1 9 24 */
     965,    /* OBJ_camellia_192_gcm             0 3 4401 5 3 1 9 26 */
     966,    /* OBJ_camellia_192_ccm             0 3 4401 5 3 1 9 27 */
     967,    /* OBJ_camellia_192_ctr             0 3 4401 5 3 1 9 29 */
     968,    /* OBJ_camellia_192_cmac            0 3 4401 5 3 1 9 30 */
     756,    /* OBJ_camellia_256_ecb             0 3 4401 5 3 1 9 41 */
     768,    /* OBJ_camellia_256_ofb128          0 3 4401 5 3 1 9 43 */
     759,    /* OBJ_camellia_256_cfb128          0 3 4401 5 3 1 9 44 */
     969,    /* OBJ_camellia_256_gcm             0 3 4401 5 3 1 9 46 */
     970,    /* OBJ_camellia_256_ccm             0 3 4401 5 3 1 9 47 */
     971,    /* OBJ_camellia_256_ctr             0 3 4401 5 3 1 9 49 */
     972,    /* OBJ_camellia_256_cmac            0 3 4401 5 3 1 9 50 */
     437,    /* OBJ_pilot                        0 9 2342 19200300 100 */
    1133,    /* OBJ_sm4_ecb                      1 2 156 10197 1 104 1 */
    1134,    /* OBJ_sm4_cbc                      1 2 156 10197 1 104 2 */
    1135,    /* OBJ_sm4_ofb128                   1 2 156 10197 1 104 3 */
    1137,    /* OBJ_sm4_cfb128                   1 2 156 10197 1 104 4 */
    1136,    /* OBJ_sm4_cfb1                     1 2 156 10197 1 104 5 */
    1138,    /* OBJ_sm4_cfb8                     1 2 156 10197 1 104 6 */
    1139,    /* OBJ_sm4_ctr                      1 2 156 10197 1 104 7 */
    1172,    /* OBJ_sm2                          1 2 156 10197 1 301 */
    1143,    /* OBJ_sm3                          1 2 156 10197 1 401 */
    1144,    /* OBJ_sm3WithRSAEncryption         1 2 156 10197 1 504 */
     776,    /* OBJ_seed_ecb                     1 2 410 200004 1 3 */
     777,    /* OBJ_seed_cbc                     1 2 410 200004 1 4 */
     779,    /* OBJ_seed_cfb128                  1 2 410 200004 1 5 */
     778,    /* OBJ_seed_ofb128                  1 2 410 200004 1 6 */
     852,    /* OBJ_id_GostR3411_94_with_GostR3410_94_cc 1 2 643 2 9 1 3 3 */
     853,    /* OBJ_id_GostR3411_94_with_GostR3410_2001_cc 1 2 643 2 9 1 3 4 */
     850,    /* OBJ_id_GostR3410_94_cc           1 2 643 2 9 1 5 3 */
     851,    /* OBJ_id_GostR3410_2001_cc         1 2 643 2 9 1 5 4 */
     849,    /* OBJ_id_Gost28147_89_cc           1 2 643 2 9 1 6 1 */
     854,    /* OBJ_id_GostR3410_2001_ParamSet_cc 1 2 643 2 9 1 8 1 */
    1004,    /* OBJ_INN                          1 2 643 3 131 1 1 */
     979,    /* OBJ_id_GostR3410_2012_256        1 2 643 7 1 1 1 1 */
     980,    /* OBJ_id_GostR3410_2012_512        1 2 643 7 1 1 1 2 */
     982,    /* OBJ_id_GostR3411_2012_256        1 2 643 7 1 1 2 2 */
     983,    /* OBJ_id_GostR3411_2012_512        1 2 643 7 1 1 2 3 */
     985,    /* OBJ_id_tc26_signwithdigest_gost3410_2012_256 1 2 643 7 1 1 3 2 */
     986,    /* OBJ_id_tc26_signwithdigest_gost3410_2012_512 1 2 643 7 1 1 3 3 */
     988,    /* OBJ_id_tc26_hmac_gost_3411_2012_256 1 2 643 7 1 1 4 1 */
     989,    /* OBJ_id_tc26_hmac_gost_3411_2012_512 1 2 643 7 1 1 4 2 */
    1173,    /* OBJ_id_tc26_cipher_gostr3412_2015_magma 1 2 643 7 1 1 5 1 */
    1176,    /* OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik 1 2 643 7 1 1 5 2 */
     992,    /* OBJ_id_tc26_agreement_gost_3410_2012_256 1 2 643 7 1 1 6 1 */
     993,    /* OBJ_id_tc26_agreement_gost_3410_2012_512 1 2 643 7 1 1 6 2 */
    1180,    /* OBJ_id_tc26_wrap_gostr3412_2015_magma 1 2 643 7 1 1 7 1 */
    1182,    /* OBJ_id_tc26_wrap_gostr3412_2015_kuznyechik 1 2 643 7 1 1 7 2 */
    1147,    /* OBJ_id_tc26_gost_3410_2012_256_constants 1 2 643 7 1 2 1 1 */
     996,    /* OBJ_id_tc26_gost_3410_2012_512_constants 1 2 643 7 1 2 1 2 */
    1002,    /* OBJ_id_tc26_gost_28147_constants 1 2 643 7 1 2 5 1 */
     186,    /* OBJ_pkcs1                        1 2 840 113549 1 1 */
      27,    /* OBJ_pkcs3                        1 2 840 113549 1 3 */
     187,    /* OBJ_pkcs5                        1 2 840 113549 1 5 */
      20,    /* OBJ_pkcs7                        1 2 840 113549 1 7 */
      47,    /* OBJ_pkcs9                        1 2 840 113549 1 9 */
       3,    /* OBJ_md2                          1 2 840 113549 2 2 */
     257,    /* OBJ_md4                          1 2 840 113549 2 4 */
       4,    /* OBJ_md5                          1 2 840 113549 2 5 */
     797,    /* OBJ_hmacWithMD5                  1 2 840 113549 2 6 */
     163,    /* OBJ_hmacWithSHA1                 1 2 840 113549 2 7 */
     798,    /* OBJ_hmacWithSHA224               1 2 840 113549 2 8 */
     799,    /* OBJ_hmacWithSHA256               1 2 840 113549 2 9 */
     800,    /* OBJ_hmacWithSHA384               1 2 840 113549 2 10 */
     801,    /* OBJ_hmacWithSHA512               1 2 840 113549 2 11 */
    1193,    /* OBJ_hmacWithSHA512_224           1 2 840 113549 2 12 */
    1194,    /* OBJ_hmacWithSHA512_256           1 2 840 113549 2 13 */
      37,    /* OBJ_rc2_cbc                      1 2 840 113549 3 2 */
       5,    /* OBJ_rc4                          1 2 840 113549 3 4 */
      44,    /* OBJ_des_ede3_cbc                 1 2 840 113549 3 7 */
     120,    /* OBJ_rc5_cbc                      1 2 840 113549 3 8 */
     643,    /* OBJ_des_cdmf                     1 2 840 113549 3 10 */
     680,    /* OBJ_X9_62_id_characteristic_two_basis 1 2 840 10045 1 2 3 */
     684,    /* OBJ_X9_62_c2pnb163v1             1 2 840 10045 3 0 1 */
     685,    /* OBJ_X9_62_c2pnb163v2             1 2 840 10045 3 0 2 */
     686,    /* OBJ_X9_62_c2pnb163v3             1 2 840 10045 3 0 3 */
     687,    /* OBJ_X9_62_c2pnb176v1             1 2 840 10045 3 0 4 */
     688,    /* OBJ_X9_62_c2tnb191v1             1 2 840 10045 3 0 5 */
     689,    /* OBJ_X9_62_c2tnb191v2             1 2 840 10045 3 0 6 */
     690,    /* OBJ_X9_62_c2tnb191v3             1 2 840 10045 3 0 7 */
     691,    /* OBJ_X9_62_c2onb191v4             1 2 840 10045 3 0 8 */
     692,    /* OBJ_X9_62_c2onb191v5             1 2 840 10045 3 0 9 */
     693,    /* OBJ_X9_62_c2pnb208w1             1 2 840 10045 3 0 10 */
     694,    /* OBJ_X9_62_c2tnb239v1             1 2 840 10045 3 0 11 */
     695,    /* OBJ_X9_62_c2tnb239v2             1 2 840 10045 3 0 12 */
     696,    /* OBJ_X9_62_c2tnb239v3             1 2 840 10045 3 0 13 */
     697,    /* OBJ_X9_62_c2onb239v4             1 2 840 10045 3 0 14 */
     698,    /* OBJ_X9_62_c2onb239v5             1 2 840 10045 3 0 15 */
     699,    /* OBJ_X9_62_c2pnb272w1             1 2 840 10045 3 0 16 */
     700,    /* OBJ_X9_62_c2pnb304w1             1 2 840 10045 3 0 17 */
     701,    /* OBJ_X9_62_c2tnb359v1             1 2 840 10045 3 0 18 */
     702,    /* OBJ_X9_62_c2pnb368w1             1 2 840 10045 3 0 19 */
     703,    /* OBJ_X9_62_c2tnb431r1             1 2 840 10045 3 0 20 */
     409,    /* OBJ_X9_62_prime192v1             1 2 840 10045 3 1 1 */
     410,    /* OBJ_X9_62_prime192v2             1 2 840 10045 3 1 2 */
     411,    /* OBJ_X9_62_prime192v3             1 2 840 10045 3 1 3 */
     412,    /* OBJ_X9_62_prime239v1             1 2 840 10045 3 1 4 */
     413,    /* OBJ_X9_62_prime239v2             1 2 840 10045 3 1 5 */
     414,    /* OBJ_X9_62_prime239v3             1 2 840 10045 3 1 6 */
     415,    /* OBJ_X9_62_prime256v1             1 2 840 10045 3 1 7 */
     793,    /* OBJ_ecdsa_with_SHA224            1 2 840 10045 4 3 1 */
     794,    /* OBJ_ecdsa_with_SHA256            1 2 840 10045 4 3 2 */
     795,    /* OBJ_ecdsa_with_SHA384            1 2 840 10045 4 3 3 */
     796,    /* OBJ_ecdsa_with_SHA512            1 2 840 10045 4 3 4 */
     269,    /* OBJ_id_pkix1_explicit_88         1 3 6 1 5 5 7 0 1 */
     270,    /* OBJ_id_pkix1_implicit_88         1 3 6 1 5 5 7 0 2 */
     271,    /* OBJ_id_pkix1_explicit_93         1 3 6 1 5 5 7 0 3 */
     272,    /* OBJ_id_pkix1_implicit_93         1 3 6 1 5 5 7 0 4 */
     273,    /* OBJ_id_mod_crmf                  1 3 6 1 5 5 7 0 5 */
     274,    /* OBJ_id_mod_cmc                   1 3 6 1 5 5 7 0 6 */
     275,    /* OBJ_id_mod_kea_profile_88        1 3 6 1 5 5 7 0 7 */
     276,    /* OBJ_id_mod_kea_profile_93        1 3 6 1 5 5 7 0 8 */
     277,    /* OBJ_id_mod_cmp                   1 3 6 1 5 5 7 0 9 */
     278,    /* OBJ_id_mod_qualified_cert_88     1 3 6 1 5 5 7 0 10 */
     279,    /* OBJ_id_mod_qualified_cert_93     1 3 6 1 5 5 7 0 11 */
     280,    /* OBJ_id_mod_attribute_cert        1 3 6 1 5 5 7 0 12 */
     281,    /* OBJ_id_mod_timestamp_protocol    1 3 6 1 5 5 7 0 13 */
     282,    /* OBJ_id_mod_ocsp                  1 3 6 1 5 5 7 0 14 */
     283,    /* OBJ_id_mod_dvcs                  1 3 6 1 5 5 7 0 15 */
     284,    /* OBJ_id_mod_cmp2000               1 3 6 1 5 5 7 0 16 */
     177,    /* OBJ_info_access                  1 3 6 1 5 5 7 1 1 */
     285,    /* OBJ_biometricInfo                1 3 6 1 5 5 7 1 2 */
     286,    /* OBJ_qcStatements                 1 3 6 1 5 5 7 1 3 */
     287,    /* OBJ_ac_auditEntity               1 3 6 1 5 5 7 1 4 */
     288,    /* OBJ_ac_targeting                 1 3 6 1 5 5 7 1 5 */
     289,    /* OBJ_aaControls                   1 3 6 1 5 5 7 1 6 */
     290,    /* OBJ_sbgp_ipAddrBlock             1 3 6 1 5 5 7 1 7 */
     291,    /* OBJ_sbgp_autonomousSysNum        1 3 6 1 5 5 7 1 8 */
     292,    /* OBJ_sbgp_routerIdentifier        1 3 6 1 5 5 7 1 9 */
     397,    /* OBJ_ac_proxying                  1 3 6 1 5 5 7 1 10 */
     398,    /* OBJ_sinfo_access                 1 3 6 1 5 5 7 1 11 */
     663,    /* OBJ_proxyCertInfo                1 3 6 1 5 5 7 1 14 */
    1020,    /* OBJ_tlsfeature                   1 3 6 1 5 5 7 1 24 */
     164,    /* OBJ_id_qt_cps                    1 3 6 1 5 5 7 2 1 */
     165,    /* OBJ_id_qt_unotice                1 3 6 1 5 5 7 2 2 */
     293,    /* OBJ_textNotice                   1 3 6 1 5 5 7 2 3 */
     129,    /* OBJ_server_auth                  1 3 6 1 5 5 7 3 1 */
     130,    /* OBJ_client_auth                  1 3 6 1 5 5 7 3 2 */
     131,    /* OBJ_code_sign                    1 3 6 1 5 5 7 3 3 */
     132,    /* OBJ_email_protect                1 3 6 1 5 5 7 3 4 */
     294,    /* OBJ_ipsecEndSystem               1 3 6 1 5 5 7 3 5 */
     295,    /* OBJ_ipsecTunnel                  1 3 6 1 5 5 7 3 6 */
     296,    /* OBJ_ipsecUser                    1 3 6 1 5 5 7 3 7 */
     133,    /* OBJ_time_stamp                   1 3 6 1 5 5 7 3 8 */
     180,    /* OBJ_OCSP_sign                    1 3 6 1 5 5 7 3 9 */
     297,    /* OBJ_dvcs                         1 3 6 1 5 5 7 3 10 */
    1022,    /* OBJ_ipsec_IKE                    1 3 6 1 5 5 7 3 17 */
    1023,    /* OBJ_capwapAC                     1 3 6 1 5 5 7 3 18 */
    1024,    /* OBJ_capwapWTP                    1 3 6 1 5 5 7 3 19 */
    1025,    /* OBJ_sshClient                    1 3 6 1 5 5 7 3 21 */
    1026,    /* OBJ_sshServer                    1 3 6 1 5 5 7 3 22 */
    1027,    /* OBJ_sendRouter                   1 3 6 1 5 5 7 3 23 */
    1028,    /* OBJ_sendProxiedRouter            1 3 6 1 5 5 7 3 24 */
    1029,    /* OBJ_sendOwner                    1 3 6 1 5 5 7 3 25 */
    1030,    /* OBJ_sendProxiedOwner             1 3 6 1 5 5 7 3 26 */
    1131,    /* OBJ_cmcCA                        1 3 6 1 5 5 7 3 27 */
    1132,    /* OBJ_cmcRA                        1 3 6 1 5 5 7 3 28 */
     298,    /* OBJ_id_it_caProtEncCert          1 3 6 1 5 5 7 4 1 */
     299,    /* OBJ_id_it_signKeyPairTypes       1 3 6 1 5 5 7 4 2 */
     300,    /* OBJ_id_it_encKeyPairTypes        1 3 6 1 5 5 7 4 3 */
     301,    /* OBJ_id_it_preferredSymmAlg       1 3 6 1 5 5 7 4 4 */
     302,    /* OBJ_id_it_caKeyUpdateInfo        1 3 6 1 5 5 7 4 5 */
     303,    /* OBJ_id_it_currentCRL             1 3 6 1 5 5 7 4 6 */
     304,    /* OBJ_id_it_unsupportedOIDs        1 3 6 1 5 5 7 4 7 */
     305,    /* OBJ_id_it_subscriptionRequest    1 3 6 1 5 5 7 4 8 */
     306,    /* OBJ_id_it_subscriptionResponse   1 3 6 1 5 5 7 4 9 */
     307,    /* OBJ_id_it_keyPairParamReq        1 3 6 1 5 5 7 4 10 */
     308,    /* OBJ_id_it_keyPairParamRep        1 3 6 1 5 5 7 4 11 */
     309,    /* OBJ_id_it_revPassphrase          1 3 6 1 5 5 7 4 12 */
     310,    /* OBJ_id_it_implicitConfirm        1 3 6 1 5 5 7 4 13 */
     311,    /* OBJ_id_it_confirmWaitTime        1 3 6 1 5 5 7 4 14 */
     312,    /* OBJ_id_it_origPKIMessage         1 3 6 1 5 5 7 4 15 */
     784,    /* OBJ_id_it_suppLangTags           1 3 6 1 5 5 7 4 16 */
     313,    /* OBJ_id_regCtrl                   1 3 6 1 5 5 7 5 1 */
     314,    /* OBJ_id_regInfo                   1 3 6 1 5 5 7 5 2 */
     323,    /* OBJ_id_alg_des40                 1 3 6 1 5 5 7 6 1 */
     324,    /* OBJ_id_alg_noSignature           1 3 6 1 5 5 7 6 2 */
     325,    /* OBJ_id_alg_dh_sig_hmac_sha1      1 3 6 1 5 5 7 6 3 */
     326,    /* OBJ_id_alg_dh_pop                1 3 6 1 5 5 7 6 4 */
     327,    /* OBJ_id_cmc_statusInfo            1 3 6 1 5 5 7 7 1 */
     328,    /* OBJ_id_cmc_identification        1 3 6 1 5 5 7 7 2 */
     329,    /* OBJ_id_cmc_identityProof         1 3 6 1 5 5 7 7 3 */
     330,    /* OBJ_id_cmc_dataReturn            1 3 6 1 5 5 7 7 4 */
     331,    /* OBJ_id_cmc_transactionId         1 3 6 1 5 5 7 7 5 */
     332,    /* OBJ_id_cmc_senderNonce           1 3 6 1 5 5 7 7 6 */
     333,    /* OBJ_id_cmc_recipientNonce        1 3 6 1 5 5 7 7 7 */
     334,    /* OBJ_id_cmc_addExtensions         1 3 6 1 5 5 7 7 8 */
     335,    /* OBJ_id_cmc_encryptedPOP          1 3 6 1 5 5 7 7 9 */
     336,    /* OBJ_id_cmc_decryptedPOP          1 3 6 1 5 5 7 7 10 */
     337,    /* OBJ_id_cmc_lraPOPWitness         1 3 6 1 5 5 7 7 11 */
     338,    /* OBJ_id_cmc_getCert               1 3 6 1 5 5 7 7 15 */
     339,    /* OBJ_id_cmc_getCRL                1 3 6 1 5 5 7 7 16 */
     340,    /* OBJ_id_cmc_revokeRequest         1 3 6 1 5 5 7 7 17 */
     341,    /* OBJ_id_cmc_regInfo               1 3 6 1 5 5 7 7 18 */
     342,    /* OBJ_id_cmc_responseInfo          1 3 6 1 5 5 7 7 19 */
     343,    /* OBJ_id_cmc_queryPending          1 3 6 1 5 5 7 7 21 */
     344,    /* OBJ_id_cmc_popLinkRandom         1 3 6 1 5 5 7 7 22 */
     345,    /* OBJ_id_cmc_popLinkWitness        1 3 6 1 5 5 7 7 23 */
     346,    /* OBJ_id_cmc_confirmCertAcceptance 1 3 6 1 5 5 7 7 24 */
     347,    /* OBJ_id_on_personalData           1 3 6 1 5 5 7 8 1 */
     858,    /* OBJ_id_on_permanentIdentifier    1 3 6 1 5 5 7 8 3 */
     348,    /* OBJ_id_pda_dateOfBirth           1 3 6 1 5 5 7 9 1 */
     349,    /* OBJ_id_pda_placeOfBirth          1 3 6 1 5 5 7 9 2 */
     351,    /* OBJ_id_pda_gender                1 3 6 1 5 5 7 9 3 */
     352,    /* OBJ_id_pda_countryOfCitizenship  1 3 6 1 5 5 7 9 4 */
     353,    /* OBJ_id_pda_countryOfResidence    1 3 6 1 5 5 7 9 5 */
     354,    /* OBJ_id_aca_authenticationInfo    1 3 6 1 5 5 7 10 1 */
     355,    /* OBJ_id_aca_accessIdentity        1 3 6 1 5 5 7 10 2 */
     356,    /* OBJ_id_aca_chargingIdentity      1 3 6 1 5 5 7 10 3 */
     357,    /* OBJ_id_aca_group                 1 3 6 1 5 5 7 10 4 */
     358,    /* OBJ_id_aca_role                  1 3 6 1 5 5 7 10 5 */
     399,    /* OBJ_id_aca_encAttrs              1 3 6 1 5 5 7 10 6 */
     359,    /* OBJ_id_qcs_pkixQCSyntax_v1       1 3 6 1 5 5 7 11 1 */
     360,    /* OBJ_id_cct_crs                   1 3 6 1 5 5 7 12 1 */
     361,    /* OBJ_id_cct_PKIData               1 3 6 1 5 5 7 12 2 */
     362,    /* OBJ_id_cct_PKIResponse           1 3 6 1 5 5 7 12 3 */
     664,    /* OBJ_id_ppl_anyLanguage           1 3 6 1 5 5 7 21 0 */
     665,    /* OBJ_id_ppl_inheritAll            1 3 6 1 5 5 7 21 1 */
     667,    /* OBJ_Independent                  1 3 6 1 5 5 7 21 2 */
     178,    /* OBJ_ad_OCSP                      1 3 6 1 5 5 7 48 1 */
     179,    /* OBJ_ad_ca_issuers                1 3 6 1 5 5 7 48 2 */
     363,    /* OBJ_ad_timeStamping              1 3 6 1 5 5 7 48 3 */
     364,    /* OBJ_ad_dvcs                      1 3 6 1 5 5 7 48 4 */
     785,    /* OBJ_caRepository                 1 3 6 1 5 5 7 48 5 */
     780,    /* OBJ_hmac_md5                     1 3 6 1 5 5 8 1 1 */
     781,    /* OBJ_hmac_sha1                    1 3 6 1 5 5 8 1 2 */
     913,    /* OBJ_aes_128_xts                  1 3 111 2 1619 0 1 1 */
     914,    /* OBJ_aes_256_xts                  1 3 111 2 1619 0 1 2 */
      58,    /* OBJ_netscape_cert_extension      2 16 840 1 113730 1 */
      59,    /* OBJ_netscape_data_type           2 16 840 1 113730 2 */
     438,    /* OBJ_pilotAttributeType           0 9 2342 19200300 100 1 */
     439,    /* OBJ_pilotAttributeSyntax         0 9 2342 19200300 100 3 */
     440,    /* OBJ_pilotObjectClass             0 9 2342 19200300 100 4 */
     441,    /* OBJ_pilotGroups                  0 9 2342 19200300 100 10 */
    1065,    /* OBJ_aria_128_ecb                 1 2 410 200046 1 1 1 */
    1066,    /* OBJ_aria_128_cbc                 1 2 410 200046 1 1 2 */
    1067,    /* OBJ_aria_128_cfb128              1 2 410 200046 1 1 3 */
    1068,    /* OBJ_aria_128_ofb128              1 2 410 200046 1 1 4 */
    1069,    /* OBJ_aria_128_ctr                 1 2 410 200046 1 1 5 */
    1070,    /* OBJ_aria_192_ecb                 1 2 410 200046 1 1 6 */
    1071,    /* OBJ_aria_192_cbc                 1 2 410 200046 1 1 7 */
    1072,    /* OBJ_aria_192_cfb128              1 2 410 200046 1 1 8 */
    1073,    /* OBJ_aria_192_ofb128              1 2 410 200046 1 1 9 */
    1074,    /* OBJ_aria_192_ctr                 1 2 410 200046 1 1 10 */
    1075,    /* OBJ_aria_256_ecb                 1 2 410 200046 1 1 11 */
    1076,    /* OBJ_aria_256_cbc                 1 2 410 200046 1 1 12 */
    1077,    /* OBJ_aria_256_cfb128              1 2 410 200046 1 1 13 */
    1078,    /* OBJ_aria_256_ofb128              1 2 410 200046 1 1 14 */
    1079,    /* OBJ_aria_256_ctr                 1 2 410 200046 1 1 15 */
    1123,    /* OBJ_aria_128_gcm                 1 2 410 200046 1 1 34 */
    1124,    /* OBJ_aria_192_gcm                 1 2 410 200046 1 1 35 */
    1125,    /* OBJ_aria_256_gcm                 1 2 410 200046 1 1 36 */
    1120,    /* OBJ_aria_128_ccm                 1 2 410 200046 1 1 37 */
    1121,    /* OBJ_aria_192_ccm                 1 2 410 200046 1 1 38 */
    1122,    /* OBJ_aria_256_ccm                 1 2 410 200046 1 1 39 */
    1174,    /* OBJ_id_tc26_cipher_gostr3412_2015_magma_ctracpkm 1 2 643 7 1 1 5 1 1 */
    1175,    /* OBJ_id_tc26_cipher_gostr3412_2015_magma_ctracpkm_omac 1 2 643 7 1 1 5 1 2 */
    1177,    /* OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm 1 2 643 7 1 1 5 2 1 */
    1178,    /* OBJ_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm_omac 1 2 643 7 1 1 5 2 2 */
    1181,    /* OBJ_id_tc26_wrap_gostr3412_2015_magma_kexp15 1 2 643 7 1 1 7 1 1 */
    1183,    /* OBJ_id_tc26_wrap_gostr3412_2015_kuznyechik_kexp15 1 2 643 7 1 1 7 2 1 */
    1148,    /* OBJ_id_tc26_gost_3410_2012_256_paramSetA 1 2 643 7 1 2 1 1 1 */
    1184,    /* OBJ_id_tc26_gost_3410_2012_256_paramSetB 1 2 643 7 1 2 1 1 2 */
    1185,    /* OBJ_id_tc26_gost_3410_2012_256_paramSetC 1 2 643 7 1 2 1 1 3 */
    1186,    /* OBJ_id_tc26_gost_3410_2012_256_paramSetD 1 2 643 7 1 2 1 1 4 */
     997,    /* OBJ_id_tc26_gost_3410_2012_512_paramSetTest 1 2 643 7 1 2 1 2 0 */
     998,    /* OBJ_id_tc26_gost_3410_2012_512_paramSetA 1 2 643 7 1 2 1 2 1 */
     999,    /* OBJ_id_tc26_gost_3410_2012_512_paramSetB 1 2 643 7 1 2 1 2 2 */
    1149,    /* OBJ_id_tc26_gost_3410_2012_512_paramSetC 1 2 643 7 1 2 1 2 3 */
    1003,    /* OBJ_id_tc26_gost_28147_param_Z   1 2 643 7 1 2 5 1 1 */
     108,    /* OBJ_cast5_cbc                    1 2 840 113533 7 66 10 */
     112,    /* OBJ_pbeWithMD5AndCast5_CBC       1 2 840 113533 7 66 12 */
     782,    /* OBJ_id_PasswordBasedMAC          1 2 840 113533 7 66 13 */
     783,    /* OBJ_id_DHBasedMac                1 2 840 113533 7 66 30 */
       6,    /* OBJ_rsaEncryption                1 2 840 113549 1 1 1 */
       7,    /* OBJ_md2WithRSAEncryption         1 2 840 113549 1 1 2 */
     396,    /* OBJ_md4WithRSAEncryption         1 2 840 113549 1 1 3 */
       8,    /* OBJ_md5WithRSAEncryption         1 2 840 113549 1 1 4 */
      65,    /* OBJ_sha1WithRSAEncryption        1 2 840 113549 1 1 5 */
     644,    /* OBJ_rsaOAEPEncryptionSET         1 2 840 113549 1 1 6 */
     919,    /* OBJ_rsaesOaep                    1 2 840 113549 1 1 7 */
     911,    /* OBJ_mgf1                         1 2 840 113549 1 1 8 */
     935,    /* OBJ_pSpecified                   1 2 840 113549 1 1 9 */
     912,    /* OBJ_rsassaPss                    1 2 840 113549 1 1 10 */
     668,    /* OBJ_sha256WithRSAEncryption      1 2 840 113549 1 1 11 */
     669,    /* OBJ_sha384WithRSAEncryption      1 2 840 113549 1 1 12 */
     670,    /* OBJ_sha512WithRSAEncryption      1 2 840 113549 1 1 13 */
     671,    /* OBJ_sha224WithRSAEncryption      1 2 840 113549 1 1 14 */
    1145,    /* OBJ_sha512_224WithRSAEncryption  1 2 840 113549 1 1 15 */
    1146,    /* OBJ_sha512_256WithRSAEncryption  1 2 840 113549 1 1 16 */
      28,    /* OBJ_dhKeyAgreement               1 2 840 113549 1 3 1 */
       9,    /* OBJ_pbeWithMD2AndDES_CBC         1 2 840 113549 1 5 1 */
      10,    /* OBJ_pbeWithMD5AndDES_CBC         1 2 840 113549 1 5 3 */
     168,    /* OBJ_pbeWithMD2AndRC2_CBC         1 2 840 113549 1 5 4 */
     169,    /* OBJ_pbeWithMD5AndRC2_CBC         1 2 840 113549 1 5 6 */
     170,    /* OBJ_pbeWithSHA1AndDES_CBC        1 2 840 113549 1 5 10 */
      68,    /* OBJ_pbeWithSHA1AndRC2_CBC        1 2 840 113549 1 5 11 */
      69,    /* OBJ_id_pbkdf2                    1 2 840 113549 1 5 12 */
     161,    /* OBJ_pbes2                        1 2 840 113549 1 5 13 */
     162,    /* OBJ_pbmac1                       1 2 840 113549 1 5 14 */
      21,    /* OBJ_pkcs7_data                   1 2 840 113549 1 7 1 */
      22,    /* OBJ_pkcs7_signed                 1 2 840 113549 1 7 2 */
      23,    /* OBJ_pkcs7_enveloped              1 2 840 113549 1 7 3 */
      24,    /* OBJ_pkcs7_signedAndEnveloped     1 2 840 113549 1 7 4 */
      25,    /* OBJ_pkcs7_digest                 1 2 840 113549 1 7 5 */
      26,    /* OBJ_pkcs7_encrypted              1 2 840 113549 1 7 6 */
      48,    /* OBJ_pkcs9_emailAddress           1 2 840 113549 1 9 1 */
      49,    /* OBJ_pkcs9_unstructuredName       1 2 840 113549 1 9 2 */
      50,    /* OBJ_pkcs9_contentType            1 2 840 113549 1 9 3 */
      51,    /* OBJ_pkcs9_messageDigest          1 2 840 113549 1 9 4 */
      52,    /* OBJ_pkcs9_signingTime            1 2 840 113549 1 9 5 */
      53,    /* OBJ_pkcs9_countersignature       1 2 840 113549 1 9 6 */
      54,    /* OBJ_pkcs9_challengePassword      1 2 840 113549 1 9 7 */
      55,    /* OBJ_pkcs9_unstructuredAddress    1 2 840 113549 1 9 8 */
      56,    /* OBJ_pkcs9_extCertAttributes      1 2 840 113549 1 9 9 */
     172,    /* OBJ_ext_req                      1 2 840 113549 1 9 14 */
     167,    /* OBJ_SMIMECapabilities            1 2 840 113549 1 9 15 */
     188,    /* OBJ_SMIME                        1 2 840 113549 1 9 16 */
     156,    /* OBJ_friendlyName                 1 2 840 113549 1 9 20 */
     157,    /* OBJ_localKeyID                   1 2 840 113549 1 9 21 */
     681,    /* OBJ_X9_62_onBasis                1 2 840 10045 1 2 3 1 */
     682,    /* OBJ_X9_62_tpBasis                1 2 840 10045 1 2 3 2 */
     683,    /* OBJ_X9_62_ppBasis                1 2 840 10045 1 2 3 3 */
     417,    /* OBJ_ms_csp_name                  1 3 6 1 4 1 311 17 1 */
     856,    /* OBJ_LocalKeySet                  1 3 6 1 4 1 311 17 2 */
     390,    /* OBJ_dcObject                     1 3 6 1 4 1 1466 344 */
      91,    /* OBJ_bf_cbc                       1 3 6 1 4 1 3029 1 2 */
     973,    /* OBJ_id_scrypt                    1 3 6 1 4 1 11591 4 11 */
     315,    /* OBJ_id_regCtrl_regToken          1 3 6 1 5 5 7 5 1 1 */
     316,    /* OBJ_id_regCtrl_authenticator     1 3 6 1 5 5 7 5 1 2 */
     317,    /* OBJ_id_regCtrl_pkiPublicationInfo 1 3 6 1 5 5 7 5 1 3 */
     318,    /* OBJ_id_regCtrl_pkiArchiveOptions 1 3 6 1 5 5 7 5 1 4 */
     319,    /* OBJ_id_regCtrl_oldCertID         1 3 6 1 5 5 7 5 1 5 */
     320,    /* OBJ_id_regCtrl_protocolEncrKey   1 3 6 1 5 5 7 5 1 6 */
     321,    /* OBJ_id_regInfo_utf8Pairs         1 3 6 1 5 5 7 5 2 1 */
     322,    /* OBJ_id_regInfo_certReq           1 3 6 1 5 5 7 5 2 2 */
     365,    /* OBJ_id_pkix_OCSP_basic           1 3 6 1 5 5 7 48 1 1 */
     366,    /* OBJ_id_pkix_OCSP_Nonce           1 3 6 1 5 5 7 48 1 2 */
     367,    /* OBJ_id_pkix_OCSP_CrlID           1 3 6 1 5 5 7 48 1 3 */
     368,    /* OBJ_id_pkix_OCSP_acceptableResponses 1 3 6 1 5 5 7 48 1 4 */
     369,    /* OBJ_id_pkix_OCSP_noCheck         1 3 6 1 5 5 7 48 1 5 */
     370,    /* OBJ_id_pkix_OCSP_archiveCutoff   1 3 6 1 5 5 7 48 1 6 */
     371,    /* OBJ_id_pkix_OCSP_serviceLocator  1 3 6 1 5 5 7 48 1 7 */
     372,    /* OBJ_id_pkix_OCSP_extendedStatus  1 3 6 1 5 5 7 48 1 8 */
     373,    /* OBJ_id_pkix_OCSP_valid           1 3 6 1 5 5 7 48 1 9 */
     374,    /* OBJ_id_pkix_OCSP_path            1 3 6 1 5 5 7 48 1 10 */
     375,    /* OBJ_id_pkix_OCSP_trustRoot       1 3 6 1 5 5 7 48 1 11 */
     921,    /* OBJ_brainpoolP160r1              1 3 36 3 3 2 8 1 1 1 */
     922,    /* OBJ_brainpoolP160t1              1 3 36 3 3 2 8 1 1 2 */
     923,    /* OBJ_brainpoolP192r1              1 3 36 3 3 2 8 1 1 3 */
     924,    /* OBJ_brainpoolP192t1              1 3 36 3 3 2 8 1 1 4 */
     925,    /* OBJ_brainpoolP224r1              1 3 36 3 3 2 8 1 1 5 */
     926,    /* OBJ_brainpoolP224t1              1 3 36 3 3 2 8 1 1 6 */
     927,    /* OBJ_brainpoolP256r1              1 3 36 3 3 2 8 1 1 7 */
     928,    /* OBJ_brainpoolP256t1              1 3 36 3 3 2 8 1 1 8 */
     929,    /* OBJ_brainpoolP320r1              1 3 36 3 3 2 8 1 1 9 */
     930,    /* OBJ_brainpoolP320t1              1 3 36 3 3 2 8 1 1 10 */
     931,    /* OBJ_brainpoolP384r1              1 3 36 3 3 2 8 1 1 11 */
     932,    /* OBJ_brainpoolP384t1              1 3 36 3 3 2 8 1 1 12 */
     933,    /* OBJ_brainpoolP512r1              1 3 36 3 3 2 8 1 1 13 */
     934,    /* OBJ_brainpoolP512t1              1 3 36 3 3 2 8 1 1 14 */
     936,    /* OBJ_dhSinglePass_stdDH_sha1kdf_scheme 1 3 133 16 840 63 0 2 */
     941,    /* OBJ_dhSinglePass_cofactorDH_sha1kdf_scheme 1 3 133 16 840 63 0 3 */
     418,    /* OBJ_aes_128_ecb                  2 16 840 1 101 3 4 1 1 */
     419,    /* OBJ_aes_128_cbc                  2 16 840 1 101 3 4 1 2 */
     420,    /* OBJ_aes_128_ofb128               2 16 840 1 101 3 4 1 3 */
     421,    /* OBJ_aes_128_cfb128               2 16 840 1 101 3 4 1 4 */
     788,    /* OBJ_id_aes128_wrap               2 16 840 1 101 3 4 1 5 */
     895,    /* OBJ_aes_128_gcm                  2 16 840 1 101 3 4 1 6 */
     896,    /* OBJ_aes_128_ccm                  2 16 840 1 101 3 4 1 7 */
     897,    /* OBJ_id_aes128_wrap_pad           2 16 840 1 101 3 4 1 8 */
     422,    /* OBJ_aes_192_ecb                  2 16 840 1 101 3 4 1 21 */
     423,    /* OBJ_aes_192_cbc                  2 16 840 1 101 3 4 1 22 */
     424,    /* OBJ_aes_192_ofb128               2 16 840 1 101 3 4 1 23 */
     425,    /* OBJ_aes_192_cfb128               2 16 840 1 101 3 4 1 24 */
     789,    /* OBJ_id_aes192_wrap               2 16 840 1 101 3 4 1 25 */
     898,    /* OBJ_aes_192_gcm                  2 16 840 1 101 3 4 1 26 */
     899,    /* OBJ_aes_192_ccm                  2 16 840 1 101 3 4 1 27 */
     900,    /* OBJ_id_aes192_wrap_pad           2 16 840 1 101 3 4 1 28 */
     426,    /* OBJ_aes_256_ecb                  2 16 840 1 101 3 4 1 41 */
     427,    /* OBJ_aes_256_cbc                  2 16 840 1 101 3 4 1 42 */
     428,    /* OBJ_aes_256_ofb128               2 16 840 1 101 3 4 1 43 */
     429,    /* OBJ_aes_256_cfb128               2 16 840 1 101 3 4 1 44 */
     790,    /* OBJ_id_aes256_wrap               2 16 840 1 101 3 4 1 45 */
     901,    /* OBJ_aes_256_gcm                  2 16 840 1 101 3 4 1 46 */
     902,    /* OBJ_aes_256_ccm                  2 16 840 1 101 3 4 1 47 */
     903,    /* OBJ_id_aes256_wrap_pad           2 16 840 1 101 3 4 1 48 */
     672,    /* OBJ_sha256                       2 16 840 1 101 3 4 2 1 */
     673,    /* OBJ_sha384                       2 16 840 1 101 3 4 2 2 */
     674,    /* OBJ_sha512                       2 16 840 1 101 3 4 2 3 */
     675,    /* OBJ_sha224                       2 16 840 1 101 3 4 2 4 */
    1094,    /* OBJ_sha512_224                   2 16 840 1 101 3 4 2 5 */
    1095,    /* OBJ_sha512_256                   2 16 840 1 101 3 4 2 6 */
    1096,    /* OBJ_sha3_224                     2 16 840 1 101 3 4 2 7 */
    1097,    /* OBJ_sha3_256                     2 16 840 1 101 3 4 2 8 */
    1098,    /* OBJ_sha3_384                     2 16 840 1 101 3 4 2 9 */
    1099,    /* OBJ_sha3_512                     2 16 840 1 101 3 4 2 10 */
    1100,    /* OBJ_shake128                     2 16 840 1 101 3 4 2 11 */
    1101,    /* OBJ_shake256                     2 16 840 1 101 3 4 2 12 */
    1102,    /* OBJ_hmac_sha3_224                2 16 840 1 101 3 4 2 13 */
    1103,    /* OBJ_hmac_sha3_256                2 16 840 1 101 3 4 2 14 */
    1104,    /* OBJ_hmac_sha3_384                2 16 840 1 101 3 4 2 15 */
    1105,    /* OBJ_hmac_sha3_512                2 16 840 1 101 3 4 2 16 */
     802,    /* OBJ_dsa_with_SHA224              2 16 840 1 101 3 4 3 1 */
     803,    /* OBJ_dsa_with_SHA256              2 16 840 1 101 3 4 3 2 */
    1106,    /* OBJ_dsa_with_SHA384              2 16 840 1 101 3 4 3 3 */
    1107,    /* OBJ_dsa_with_SHA512              2 16 840 1 101 3 4 3 4 */
    1108,    /* OBJ_dsa_with_SHA3_224            2 16 840 1 101 3 4 3 5 */
    1109,    /* OBJ_dsa_with_SHA3_256            2 16 840 1 101 3 4 3 6 */
    1110,    /* OBJ_dsa_with_SHA3_384            2 16 840 1 101 3 4 3 7 */
    1111,    /* OBJ_dsa_with_SHA3_512            2 16 840 1 101 3 4 3 8 */
    1112,    /* OBJ_ecdsa_with_SHA3_224          2 16 840 1 101 3 4 3 9 */
    1113,    /* OBJ_ecdsa_with_SHA3_256          2 16 840 1 101 3 4 3 10 */
    1114,    /* OBJ_ecdsa_with_SHA3_384          2 16 840 1 101 3 4 3 11 */
    1115,    /* OBJ_ecdsa_with_SHA3_512          2 16 840 1 101 3 4 3 12 */
    1116,    /* OBJ_RSA_SHA3_224                 2 16 840 1 101 3 4 3 13 */
    1117,    /* OBJ_RSA_SHA3_256                 2 16 840 1 101 3 4 3 14 */
    1118,    /* OBJ_RSA_SHA3_384                 2 16 840 1 101 3 4 3 15 */
    1119,    /* OBJ_RSA_SHA3_512                 2 16 840 1 101 3 4 3 16 */
      71,    /* OBJ_netscape_cert_type           2 16 840 1 113730 1 1 */
      72,    /* OBJ_netscape_base_url            2 16 840 1 113730 1 2 */
      73,    /* OBJ_netscape_revocation_url      2 16 840 1 113730 1 3 */
      74,    /* OBJ_netscape_ca_revocation_url   2 16 840 1 113730 1 4 */
      75,    /* OBJ_netscape_renewal_url         2 16 840 1 113730 1 7 */
      76,    /* OBJ_netscape_ca_policy_url       2 16 840 1 113730 1 8 */
      77,    /* OBJ_netscape_ssl_server_name     2 16 840 1 113730 1 12 */
      78,    /* OBJ_netscape_comment             2 16 840 1 113730 1 13 */
      79,    /* OBJ_netscape_cert_sequence       2 16 840 1 113730 2 5 */
     139,    /* OBJ_ns_sgc                       2 16 840 1 113730 4 1 */
     458,    /* OBJ_userId                       0 9 2342 19200300 100 1 1 */
     459,    /* OBJ_textEncodedORAddress         0 9 2342 19200300 100 1 2 */
     460,    /* OBJ_rfc822Mailbox                0 9 2342 19200300 100 1 3 */
     461,    /* OBJ_info                         0 9 2342 19200300 100 1 4 */
     462,    /* OBJ_favouriteDrink               0 9 2342 19200300 100 1 5 */
     463,    /* OBJ_roomNumber                   0 9 2342 19200300 100 1 6 */
     464,    /* OBJ_photo                        0 9 2342 19200300 100 1 7 */
     465,    /* OBJ_userClass                    0 9 2342 19200300 100 1 8 */
     466,    /* OBJ_host                         0 9 2342 19200300 100 1 9 */
     467,    /* OBJ_manager                      0 9 2342 19200300 100 1 10 */
     468,    /* OBJ_documentIdentifier           0 9 2342 19200300 100 1 11 */
     469,    /* OBJ_documentTitle                0 9 2342 19200300 100 1 12 */
     470,    /* OBJ_documentVersion              0 9 2342 19200300 100 1 13 */
     471,    /* OBJ_documentAuthor               0 9 2342 19200300 100 1 14 */
     472,    /* OBJ_documentLocation             0 9 2342 19200300 100 1 15 */
     473,    /* OBJ_homeTelephoneNumber          0 9 2342 19200300 100 1 20 */
     474,    /* OBJ_secretary                    0 9 2342 19200300 100 1 21 */
     475,    /* OBJ_otherMailbox                 0 9 2342 19200300 100 1 22 */
     476,    /* OBJ_lastModifiedTime             0 9 2342 19200300 100 1 23 */
     477,    /* OBJ_lastModifiedBy               0 9 2342 19200300 100 1 24 */
     391,    /* OBJ_domainComponent              0 9 2342 19200300 100 1 25 */
     478,    /* OBJ_aRecord                      0 9 2342 19200300 100 1 26 */
     479,    /* OBJ_pilotAttributeType27         0 9 2342 19200300 100 1 27 */
     480,    /* OBJ_mXRecord                     0 9 2342 19200300 100 1 28 */
     481,    /* OBJ_nSRecord                     0 9 2342 19200300 100 1 29 */
     482,    /* OBJ_sOARecord                    0 9 2342 19200300 100 1 30 */
     483,    /* OBJ_cNAMERecord                  0 9 2342 19200300 100 1 31 */
     484,    /* OBJ_associatedDomain             0 9 2342 19200300 100 1 37 */
     485,    /* OBJ_associatedName               0 9 2342 19200300 100 1 38 */
     486,    /* OBJ_homePostalAddress            0 9 2342 19200300 100 1 39 */
     487,    /* OBJ_personalTitle                0 9 2342 19200300 100 1 40 */
     488,    /* OBJ_mobileTelephoneNumber        0 9 2342 19200300 100 1 41 */
     489,    /* OBJ_pagerTelephoneNumber         0 9 2342 19200300 100 1 42 */
     490,    /* OBJ_friendlyCountryName          0 9 2342 19200300 100 1 43 */
     102,    /* OBJ_uniqueIdentifier             0 9 2342 19200300 100 1 44 */
     491,    /* OBJ_organizationalStatus         0 9 2342 19200300 100 1 45 */
     492,    /* OBJ_janetMailbox                 0 9 2342 19200300 100 1 46 */
     493,    /* OBJ_mailPreferenceOption         0 9 2342 19200300 100 1 47 */
     494,    /* OBJ_buildingName                 0 9 2342 19200300 100 1 48 */
     495,    /* OBJ_dSAQuality                   0 9 2342 19200300 100 1 49 */
     496,    /* OBJ_singleLevelQuality           0 9 2342 19200300 100 1 50 */
     497,    /* OBJ_subtreeMinimumQuality        0 9 2342 19200300 100 1 51 */
     498,    /* OBJ_subtreeMaximumQuality        0 9 2342 19200300 100 1 52 */
     499,    /* OBJ_personalSignature            0 9 2342 19200300 100 1 53 */
     500,    /* OBJ_dITRedirect                  0 9 2342 19200300 100 1 54 */
     501,    /* OBJ_audio                        0 9 2342 19200300 100 1 55 */
     502,    /* OBJ_documentPublisher            0 9 2342 19200300 100 1 56 */
     442,    /* OBJ_iA5StringSyntax              0 9 2342 19200300 100 3 4 */
     443,    /* OBJ_caseIgnoreIA5StringSyntax    0 9 2342 19200300 100 3 5 */
     444,    /* OBJ_pilotObject                  0 9 2342 19200300 100 4 3 */
     445,    /* OBJ_pilotPerson                  0 9 2342 19200300 100 4 4 */
     446,    /* OBJ_account                      0 9 2342 19200300 100 4 5 */
     447,    /* OBJ_document                     0 9 2342 19200300 100 4 6 */
     448,    /* OBJ_room                         0 9 2342 19200300 100 4 7 */
     449,    /* OBJ_documentSeries               0 9 2342 19200300 100 4 9 */
     392,    /* OBJ_Domain                       0 9 2342 19200300 100 4 13 */
     450,    /* OBJ_rFC822localPart              0 9 2342 19200300 100 4 14 */
     451,    /* OBJ_dNSDomain                    0 9 2342 19200300 100 4 15 */
     452,    /* OBJ_domainRelatedObject          0 9 2342 19200300 100 4 17 */
     453,    /* OBJ_friendlyCountry              0 9 2342 19200300 100 4 18 */
     454,    /* OBJ_simpleSecurityObject         0 9 2342 19200300 100 4 19 */
     455,    /* OBJ_pilotOrganization            0 9 2342 19200300 100 4 20 */
     456,    /* OBJ_pilotDSA                     0 9 2342 19200300 100 4 21 */
     457,    /* OBJ_qualityLabelledData          0 9 2342 19200300 100 4 22 */
    1152,    /* OBJ_dstu28147                    1 2 804 2 1 1 1 1 1 1 */
    1156,    /* OBJ_hmacWithDstu34311            1 2 804 2 1 1 1 1 1 2 */
    1157,    /* OBJ_dstu34311                    1 2 804 2 1 1 1 1 2 1 */
     189,    /* OBJ_id_smime_mod                 1 2 840 113549 1 9 16 0 */
     190,    /* OBJ_id_smime_ct                  1 2 840 113549 1 9 16 1 */
     191,    /* OBJ_id_smime_aa                  1 2 840 113549 1 9 16 2 */
     192,    /* OBJ_id_smime_alg                 1 2 840 113549 1 9 16 3 */
     193,    /* OBJ_id_smime_cd                  1 2 840 113549 1 9 16 4 */
     194,    /* OBJ_id_smime_spq                 1 2 840 113549 1 9 16 5 */
     195,    /* OBJ_id_smime_cti                 1 2 840 113549 1 9 16 6 */
     158,    /* OBJ_x509Certificate              1 2 840 113549 1 9 22 1 */
     159,    /* OBJ_sdsiCertificate              1 2 840 113549 1 9 22 2 */
     160,    /* OBJ_x509Crl                      1 2 840 113549 1 9 23 1 */
     144,    /* OBJ_pbe_WithSHA1And128BitRC4     1 2 840 113549 1 12 1 1 */
     145,    /* OBJ_pbe_WithSHA1And40BitRC4      1 2 840 113549 1 12 1 2 */
     146,    /* OBJ_pbe_WithSHA1And3_Key_TripleDES_CBC 1 2 840 113549 1 12 1 3 */
     147,    /* OBJ_pbe_WithSHA1And2_Key_TripleDES_CBC 1 2 840 113549 1 12 1 4 */
     148,    /* OBJ_pbe_WithSHA1And128BitRC2_CBC 1 2 840 113549 1 12 1 5 */
     149,    /* OBJ_pbe_WithSHA1And40BitRC2_CBC  1 2 840 113549 1 12 1 6 */
     171,    /* OBJ_ms_ext_req                   1 3 6 1 4 1 311 2 1 14 */
     134,    /* OBJ_ms_code_ind                  1 3 6 1 4 1 311 2 1 21 */
     135,    /* OBJ_ms_code_com                  1 3 6 1 4 1 311 2 1 22 */
     136,    /* OBJ_ms_ctl_sign                  1 3 6 1 4 1 311 10 3 1 */
     137,    /* OBJ_ms_sgc                       1 3 6 1 4 1 311 10 3 3 */
     138,    /* OBJ_ms_efs                       1 3 6 1 4 1 311 10 3 4 */
     648,    /* OBJ_ms_smartcard_login           1 3 6 1 4 1 311 20 2 2 */
     649,    /* OBJ_ms_upn                       1 3 6 1 4 1 311 20 2 3 */
     951,    /* OBJ_ct_precert_scts              1 3 6 1 4 1 11129 2 4 2 */
     952,    /* OBJ_ct_precert_poison            1 3 6 1 4 1 11129 2 4 3 */
     953,    /* OBJ_ct_precert_signer            1 3 6 1 4 1 11129 2 4 4 */
     954,    /* OBJ_ct_cert_scts                 1 3 6 1 4 1 11129 2 4 5 */
     751,    /* OBJ_camellia_128_cbc             1 2 392 200011 61 1 1 1 2 */
     752,    /* OBJ_camellia_192_cbc             1 2 392 200011 61 1 1 1 3 */
     753,    /* OBJ_camellia_256_cbc             1 2 392 200011 61 1 1 1 4 */
     907,    /* OBJ_id_camellia128_wrap          1 2 392 200011 61 1 1 3 2 */
     908,    /* OBJ_id_camellia192_wrap          1 2 392 200011 61 1 1 3 3 */
     909,    /* OBJ_id_camellia256_wrap          1 2 392 200011 61 1 1 3 4 */
    1153,    /* OBJ_dstu28147_ofb                1 2 804 2 1 1 1 1 1 1 2 */
    1154,    /* OBJ_dstu28147_cfb                1 2 804 2 1 1 1 1 1 1 3 */
    1155,    /* OBJ_dstu28147_wrap               1 2 804 2 1 1 1 1 1 1 5 */
    1158,    /* OBJ_dstu4145le                   1 2 804 2 1 1 1 1 3 1 1 */
     196,    /* OBJ_id_smime_mod_cms             1 2 840 113549 1 9 16 0 1 */
     197,    /* OBJ_id_smime_mod_ess             1 2 840 113549 1 9 16 0 2 */
     198,    /* OBJ_id_smime_mod_oid             1 2 840 113549 1 9 16 0 3 */
     199,    /* OBJ_id_smime_mod_msg_v3          1 2 840 113549 1 9 16 0 4 */
     200,    /* OBJ_id_smime_mod_ets_eSignature_88 1 2 840 113549 1 9 16 0 5 */
     201,    /* OBJ_id_smime_mod_ets_eSignature_97 1 2 840 113549 1 9 16 0 6 */
     202,    /* OBJ_id_smime_mod_ets_eSigPolicy_88 1 2 840 113549 1 9 16 0 7 */
     203,    /* OBJ_id_smime_mod_ets_eSigPolicy_97 1 2 840 113549 1 9 16 0 8 */
     204,    /* OBJ_id_smime_ct_receipt          1 2 840 113549 1 9 16 1 1 */
     205,    /* OBJ_id_smime_ct_authData         1 2 840 113549 1 9 16 1 2 */
     206,    /* OBJ_id_smime_ct_publishCert      1 2 840 113549 1 9 16 1 3 */
     207,    /* OBJ_id_smime_ct_TSTInfo          1 2 840 113549 1 9 16 1 4 */
     208,    /* OBJ_id_smime_ct_TDTInfo          1 2 840 113549 1 9 16 1 5 */
     209,    /* OBJ_id_smime_ct_contentInfo      1 2 840 113549 1 9 16 1 6 */
     210,    /* OBJ_id_smime_ct_DVCSRequestData  1 2 840 113549 1 9 16 1 7 */
     211,    /* OBJ_id_smime_ct_DVCSResponseData 1 2 840 113549 1 9 16 1 8 */
     786,    /* OBJ_id_smime_ct_compressedData   1 2 840 113549 1 9 16 1 9 */
    1058,    /* OBJ_id_smime_ct_contentCollection 1 2 840 113549 1 9 16 1 19 */
    1059,    /* OBJ_id_smime_ct_authEnvelopedData 1 2 840 113549 1 9 16 1 23 */
     787,    /* OBJ_id_ct_asciiTextWithCRLF      1 2 840 113549 1 9 16 1 27 */
    1060,    /* OBJ_id_ct_xml                    1 2 840 113549 1 9 16 1 28 */
     212,    /* OBJ_id_smime_aa_receiptRequest   1 2 840 113549 1 9 16 2 1 */
     213,    /* OBJ_id_smime_aa_securityLabel    1 2 840 113549 1 9 16 2 2 */
     214,    /* OBJ_id_smime_aa_mlExpandHistory  1 2 840 113549 1 9 16 2 3 */
     215,    /* OBJ_id_smime_aa_contentHint      1 2 840 113549 1 9 16 2 4 */
     216,    /* OBJ_id_smime_aa_msgSigDigest     1 2 840 113549 1 9 16 2 5 */
     217,    /* OBJ_id_smime_aa_encapContentType 1 2 840 113549 1 9 16 2 6 */
     218,    /* OBJ_id_smime_aa_contentIdentifier 1 2 840 113549 1 9 16 2 7 */
     219,    /* OBJ_id_smime_aa_macValue         1 2 840 113549 1 9 16 2 8 */
     220,    /* OBJ_id_smime_aa_equivalentLabels 1 2 840 113549 1 9 16 2 9 */
     221,    /* OBJ_id_smime_aa_contentReference 1 2 840 113549 1 9 16 2 10 */
     222,    /* OBJ_id_smime_aa_encrypKeyPref    1 2 840 113549 1 9 16 2 11 */
     223,    /* OBJ_id_smime_aa_signingCertificate 1 2 840 113549 1 9 16 2 12 */
     224,    /* OBJ_id_smime_aa_smimeEncryptCerts 1 2 840 113549 1 9 16 2 13 */
     225,    /* OBJ_id_smime_aa_timeStampToken   1 2 840 113549 1 9 16 2 14 */
     226,    /* OBJ_id_smime_aa_ets_sigPolicyId  1 2 840 113549 1 9 16 2 15 */
     227,    /* OBJ_id_smime_aa_ets_commitmentType 1 2 840 113549 1 9 16 2 16 */
     228,    /* OBJ_id_smime_aa_ets_signerLocation 1 2 840 113549 1 9 16 2 17 */
     229,    /* OBJ_id_smime_aa_ets_signerAttr   1 2 840 113549 1 9 16 2 18 */
     230,    /* OBJ_id_smime_aa_ets_otherSigCert 1 2 840 113549 1 9 16 2 19 */
     231,    /* OBJ_id_smime_aa_ets_contentTimestamp 1 2 840 113549 1 9 16 2 20 */
     232,    /* OBJ_id_smime_aa_ets_CertificateRefs 1 2 840 113549 1 9 16 2 21 */
     233,    /* OBJ_id_smime_aa_ets_RevocationRefs 1 2 840 113549 1 9 16 2 22 */
     234,    /* OBJ_id_smime_aa_ets_certValues   1 2 840 113549 1 9 16 2 23 */
     235,    /* OBJ_id_smime_aa_ets_revocationValues 1 2 840 113549 1 9 16 2 24 */
     236,    /* OBJ_id_smime_aa_ets_escTimeStamp 1 2 840 113549 1 9 16 2 25 */
     237,    /* OBJ_id_smime_aa_ets_certCRLTimestamp 1 2 840 113549 1 9 16 2 26 */
     238,    /* OBJ_id_smime_aa_ets_archiveTimeStamp 1 2 840 113549 1 9 16 2 27 */
     239,    /* OBJ_id_smime_aa_signatureType    1 2 840 113549 1 9 16 2 28 */
     240,    /* OBJ_id_smime_aa_dvcs_dvc         1 2 840 113549 1 9 16 2 29 */
    1086,    /* OBJ_id_smime_aa_signingCertificateV2 1 2 840 113549 1 9 16 2 47 */
     241,    /* OBJ_id_smime_alg_ESDHwith3DES    1 2 840 113549 1 9 16 3 1 */
     242,    /* OBJ_id_smime_alg_ESDHwithRC2     1 2 840 113549 1 9 16 3 2 */
     243,    /* OBJ_id_smime_alg_3DESwrap        1 2 840 113549 1 9 16 3 3 */
     244,    /* OBJ_id_smime_alg_RC2wrap         1 2 840 113549 1 9 16 3 4 */
     245,    /* OBJ_id_smime_alg_ESDH            1 2 840 113549 1 9 16 3 5 */
     246,    /* OBJ_id_smime_alg_CMS3DESwrap     1 2 840 113549 1 9 16 3 6 */
     247,    /* OBJ_id_smime_alg_CMSRC2wrap      1 2 840 113549 1 9 16 3 7 */
     125,    /* OBJ_zlib_compression             1 2 840 113549 1 9 16 3 8 */
     893,    /* OBJ_id_alg_PWRI_KEK              1 2 840 113549 1 9 16 3 9 */
     248,    /* OBJ_id_smime_cd_ldap             1 2 840 113549 1 9 16 4 1 */
     249,    /* OBJ_id_smime_spq_ets_sqt_uri     1 2 840 113549 1 9 16 5 1 */
     250,    /* OBJ_id_smime_spq_ets_sqt_unotice 1 2 840 113549 1 9 16 5 2 */
     251,    /* OBJ_id_smime_cti_ets_proofOfOrigin 1 2 840 113549 1 9 16 6 1 */
     252,    /* OBJ_id_smime_cti_ets_proofOfReceipt 1 2 840 113549 1 9 16 6 2 */
     253,    /* OBJ_id_smime_cti_ets_proofOfDelivery 1 2 840 113549 1 9 16 6 3 */
     254,    /* OBJ_id_smime_cti_ets_proofOfSender 1 2 840 113549 1 9 16 6 4 */
     255,    /* OBJ_id_smime_cti_ets_proofOfApproval 1 2 840 113549 1 9 16 6 5 */
     256,    /* OBJ_id_smime_cti_ets_proofOfCreation 1 2 840 113549 1 9 16 6 6 */
     150,    /* OBJ_keyBag                       1 2 840 113549 1 12 10 1 1 */
     151,    /* OBJ_pkcs8ShroudedKeyBag          1 2 840 113549 1 12 10 1 2 */
     152,    /* OBJ_certBag                      1 2 840 113549 1 12 10 1 3 */
     153,    /* OBJ_crlBag                       1 2 840 113549 1 12 10 1 4 */
     154,    /* OBJ_secretBag                    1 2 840 113549 1 12 10 1 5 */
     155,    /* OBJ_safeContentsBag              1 2 840 113549 1 12 10 1 6 */
      34,    /* OBJ_idea_cbc                     1 3 6 1 4 1 188 7 1 1 2 */
     955,    /* OBJ_jurisdictionLocalityName     1 3 6 1 4 1 311 60 2 1 1 */
     956,    /* OBJ_jurisdictionStateOrProvinceName 1 3 6 1 4 1 311 60 2 1 2 */
     957,    /* OBJ_jurisdictionCountryName      1 3 6 1 4 1 311 60 2 1 3 */
    1056,    /* OBJ_blake2b512                   1 3 6 1 4 1 1722 12 2 1 16 */
    1057,    /* OBJ_blake2s256                   1 3 6 1 4 1 1722 12 2 2 8 */
    1159,    /* OBJ_dstu4145be                   1 2 804 2 1 1 1 1 3 1 1 1 1 */
    1160,    /* OBJ_uacurve0                     1 2 804 2 1 1 1 1 3 1 1 2 0 */
    1161,    /* OBJ_uacurve1                     1 2 804 2 1 1 1 1 3 1 1 2 1 */
    1162,    /* OBJ_uacurve2                     1 2 804 2 1 1 1 1 3 1 1 2 2 */
    1163,    /* OBJ_uacurve3                     1 2 804 2 1 1 1 1 3 1 1 2 3 */
    1164,    /* OBJ_uacurve4                     1 2 804 2 1 1 1 1 3 1 1 2 4 */
    1165,    /* OBJ_uacurve5                     1 2 804 2 1 1 1 1 3 1 1 2 5 */
    1166,    /* OBJ_uacurve6                     1 2 804 2 1 1 1 1 3 1 1 2 6 */
    1167,    /* OBJ_uacurve7                     1 2 804 2 1 1 1 1 3 1 1 2 7 */
    1168,    /* OBJ_uacurve8                     1 2 804 2 1 1 1 1 3 1 1 2 8 */
    1169,    /* OBJ_uacurve9                     1 2 804 2 1 1 1 1 3 1 1 2 9 */
};

void main()
{
}
