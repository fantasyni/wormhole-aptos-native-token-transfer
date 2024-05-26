// #[test_only]
// module wormhole_ntt::message_serialize_tests {
//     use wormhole::bytes32::{Self};
//     use wormhole::external_address::{Self};
//     use wormhole_ntt::trimmed_amount::{Self};
//     use wormhole_ntt::transceiver_message::{Self};
//     use wormhole_ntt::ntt_manager_message::{Self};
//     use wormhole_ntt::native_token_transfer::{Self};
//
//     #[test]
//     fun test_serialize_transceiver_message() {
//         let transceiver_message_1: vector<u8> = x"9945ff10042942fafabe0000000000000000000000000000000000000000000000000000042942fababe00000000000000000000000000000000000000000000000000000091128434bafe23430000000000000000000000000000000000ce00aa00000000004667921341234300000000000000000000000000000000000000000000000000004f994e545407000000000012d687beefface00000000000000000000000000000000000000000000000000000000feebcafe0000000000000000000000000000000000000000000000000000000000110000";
//
//         let ntt = native_token_transfer::new_test_only(
//             trimmed_amount::new(1234567, 7),
//             external_address::new(bytes32::from_bytes(x"BEEFFACE")),
//             external_address::new(bytes32::from_bytes(x"FEEBCAFE")),
//                     17);
//
//
//         let mm = ntt_manager_message::new_test_only(
//             bytes32::from_bytes(x"128434bafe23430000000000000000000000000000000000ce00aa0000000000"),
//             external_address::new(bytes32::from_bytes(x"46679213412343")),
//           native_token_transfer::encode_native_token_transfer_test_only(ntt)
//         );
//
//         let em = transceiver_message::build_and_encode_transceiver_message_test_only(
//             external_address::new(bytes32::from_bytes(x"042942FAFABE")),
//             external_address::new(bytes32::from_bytes(x"042942FABABE")),
//             ntt_manager_message::encode_ntt_manager_message_test_only(mm),
//             vector[]
//         );
//
//         assert!(em == transceiver_message_1, 0);
//
//         let (source_ntt_manager_address, recipient_ntt_manager_address, parsed_ntt_manager_message)
//             = transceiver_message::parse_transceiver_and_ntt_manager_message_test_only(em);
//
//         assert!(source_ntt_manager_address == external_address::new(bytes32::from_bytes(x"042942FAFABE")), 0);
//         assert!(recipient_ntt_manager_address == external_address::new(bytes32::from_bytes(x"042942FABABE")), 0);
//
//         let (id, sender, payload) = ntt_manager_message::into_message_test_only(parsed_ntt_manager_message);
//         assert!(id == bytes32::from_bytes(x"128434bafe23430000000000000000000000000000000000ce00aa0000000000"), 0);
//         assert!(sender == external_address::new(bytes32::from_bytes(x"46679213412343")), 0);
//
//         let parsed_ntt = native_token_transfer::parse_native_token_transfer_test_only(payload);
//         let (amount, source_token, to, to_chain) = native_token_transfer::into_message_test_only(parsed_ntt);
//         assert!(amount == trimmed_amount::new(1234567, 7), 0);
//         assert!(source_token == external_address::new(bytes32::from_bytes(x"BEEFFACE")), 0);
//         assert!(to == external_address::new(bytes32::from_bytes(x"FEEBCAFE")), 0);
//         assert!(to_chain == 17, 0);
//     }
// }
