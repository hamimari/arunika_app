 import 'package:arunika_app/data/models/response/signup_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';

class UserResponseConverter {
   static UserResponse toUserResponse(SignUpResponse signUpResponse) {
     return UserResponse(
       id: signUpResponse.id,
       name: signUpResponse.name,
       phoneNumber: signUpResponse.phoneNumber,
       emailAddress: signUpResponse.email,
       address: signUpResponse.address,
       city: signUpResponse.city,
       children: signUpResponse.children,
     );
   }
 }