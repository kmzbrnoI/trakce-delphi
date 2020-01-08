////////////////////////////////////////////////////////////////////////////////
// TrakceErrors.pas: Error codes definiton
////////////////////////////////////////////////////////////////////////////////

{
   LICENSE:

   Copyright 2019-2020 Jan Horacek

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
  limitations under the License.
}

{
  DESCRIPTION:

  This file defines library error codes.

  It is necessary to keep this file synced with actual library error codes!
}

unit TrakceErrors;

interface

uses SysUtils;

const
 TRK_FILE_CANNOT_ACCESS = 1010;
 TRK_FILE_DEVICE_OPENED = 1011;
 TRK_ALREADY_OPENNED = 2001;
 TRK_CANNOT_OPEN_PORT = 2002;
 TRK_NOT_OPENED = 2011;
 TRK_UNSUPPORTED_API_VERSION = 4000;

type
  TrkException = class(Exception);

  ETrkGeneralException = class(TrkException)
  public
    constructor Create();
  end;

  ETrkAlreadyOpened = class(TrkException);
  ETrkCannotOpenPort = class(TrkException);
  ETrkNotOpened = class(TrkException);

  ETrkFuncNotAssigned = class(TrkException);
  ETrkLibNotFound = class(TrkException);
  ETrkCannotLoadLib = class(TrkException);
  ETrkNoLibLoaded = class(TrkException);
  ETrkUnsupportedApiVersion = class(TrkException);

  ETrkCannotAccessFile = class(TrkException);
  ETrkDeviceOpened = class(TrkException);

implementation

constructor ETrkGeneralException.Create();
begin
 inherited Create('General exception in Trakce library!');
end;

end.

