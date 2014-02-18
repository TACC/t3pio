! -*- f90 -*-
subroutine assert(file, ln, testStr, msgIn)
   implicit none
   character(*)  :: file, testStr, msgIn
   integer       :: ln
   character(80) :: lstr

   write(lstr,'(i15)') ln

   print *, "Assert: ",trim(testStr)," Failed at ",trim(file),":",trim(adjustl(lstr))
   print *, "Msg: ", trim(msgIn)
   stop
end subroutine assert
