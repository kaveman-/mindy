// selfRunner.c

// includes

#include <Files.h>
#include <Finder.h>
#include <MacTypes.h>
#include <Resources.h>

// defines

#define kCodeFragmentType	'cfrg'
#define kCodeResourceType	'PCOD'

#define kCodeResourceNum	0	
#define kCodeFragmentNum	128


// Prototypes

OSErr MakeSelfRunner( FSSpec * from, int creator, int type );
static OSErr StartResourceFile( FSSpec * from, short * refnum, int creator, int type );
static OSErr CopyResources( short refnum, Handle pcod, Handle cfrg );
OSErr SetFinderInfo( FSSpec * file, int creator, int type );
OSErr GetSourceResource( Handle * into, int type, short number );
OSErr GetDestinationResource( Handle * into, int type, short number );
static void CopyHandle( Handle from, Handle to );

// Functions

// MakeSelfRunner
// Copies the needed resource to the given file,
// and changes it's type to 'APPL' and creator to '????' 
// Must have access to the PCOD abd cfrg routines in the resource chain
// These are extracted from a reosurce of type 'MNDI', nos 128 & 129

OSErr MakeSelfRunner( FSSpec * from, int creator, int type )
{
	OSErr err;
	short oldResFile;
	short refnum;
	
	Handle 	pcod = NULL,
			cfrg = NULL;
			
	// Get the cfrg and the code resource for the self-runner
	err =  GetSourceResource( &pcod, kCodeResourceType, kCodeResourceNum );
	if( err != noErr )
		goto finally;
	err = GetResource( &cfrg, kCodeFragmentType, kCodeFragmentNum );
	if( err != noErr )
		goto finally;
			
	// Save the old resource file
	oldResFile = CurResFile();
	
	// Start using the runner-to-be resource file
	err = StartResourceFile( from, &refnum, creator, type );
	if( err )
		goto finally;
	
	// Copy the runner resources over
	err = CopyResources( refnum, pcod, cfrg );
	if( err != noErr )
		goto finally;
		
	// Set creator and type
	err = SetFinderInfo( from, creator, type );
	if( err != noErr )
		goto finally;
	
	// finally
	
	finally:
	
	// Restore the old resource file
	UseResFile( oldResFile );
	
	// Release resources we used
	if( pcod != NULL )
		ReleaseResource( pcod );
	ReleaseResource( cfrg );
	
	return err;
}


// StartResourceFile
// Opens or creates and starts using the data file's resource fork

OSErr StartResourceFile( FSSpec * from, short * refnum, int creator, int type )
{
	OSErr err = noErr;

	// Create the resource file, or leave if already created
	FSpCreateResFile( from, creator, type, smSystemScript );
	if( ((err = ResError()) != noErr) && err != -48 )	// -48 = duplicate filename (rename)
		goto finally;
		
	// Open the resource file	
	*refnum = FSpOpenResFile( from, fsRdWrPerm );
	err = ResError();
	if( err != noErr )
		goto finally;
	
	// Set as current file
	UseResFile( *refnum );
	
	
	// finally
	
	finally:
	
	return err;
}


// CopyResources
// Copies over the PCOD and cfrg resources needed to make a self-runner

OSErr CopyResources( short refnum, Handle pcod, Handle cfrg )
{
	OSErr err = noErr;
	Handle pcodCopy = NULL,
			cfrgCopy = NULL;

	// Get or make PCOD in the target file
	err = GetDestinationResource( &pcodCopy, kCodeResourceType, kCodeResourceNum );
	if( err != noErr )
		goto finally;
		
	// Get or make cfrg in the target file
	err = Get1Resource( &cfrgCopy, kCodeFragmentType, 0 );
	if( err != noErr )
		goto finally;
		
	// Copy over the resources

	CopyHandle( pcod, pcodCopy );
	CopyHandle( cfrg, cfrgCopy );
	
	// Write ENTIRE RESOURCE MAP to disk
	UpdateResFile( refnum );
	
	// finally
	
	finally:
	
	// Release resources we made
	if( pcodCopy != NULL )
		ReleaseResource( pcodCopy );
	if( cfrgCopy != NULL )
		ReleaseResource( cfrgCopy );
	
	return err;
}


// SetFinderInfo
// Set the file's creator and type

OSErr SetFinderInfo( FSSpec * file, int creator, int type )
{
	OSErr err;
	FInfo info;
	
	// Get FInfo
	err = FSpGetFInfo( file, &info );
	if( err )
		goto finally;
		
	// Set type and creator	
	info.fdType = type;
	info.fdCreator = creator;

	// Set FInfo
	err = FSpSetFInfo( file, &info );
	if( err )
		goto finally;
	
	// finally
	
	finally:
	
	return err;
}

// GetSourceResource

OSErr GetSourceResource( Handle * into, int type, short number )
{
	OSErr err;
	
	// Get the cfrg and the code resource for the self-runner
	*into = GetResource( type, number );
	if( *into == NULL )
	{
		err = -1;
		goto finally;
	}
	if( (err = ResError()) != noErr )
		goto finally;
	
	// finally 
	
	finally:
	
	return err;
}

// GetDestinationResource

OSErr GetDestinationResource( Handle * into, int type, short number )
{
	*into = Get1Resource( type, number );
	if( (*into == NULL) || (ResError() != noErr) )
	{
		*into = NewHandle( 1 );
		if( cfrgCopy == NULL )
		{
			err = -1;
			goto finally;
		}
		else if( (err = ResError())!= noErr )
			goto finally;
		
		AddResource( *into,type, number, "\p" );
	}

	
	// finally 
	
	finally:
	
	return err;
}


// CopyHandle
// Copy from one handle to another

void CopyHandle( Handle from, Handle to )
{
	HLock( from );
	HLock( to );
	
	SetResourceSize( to, GetResourceSize( from ) );
	BlockMove( *from, *to, GetHandleSize( from ) );
	
	HUnlock( from );
	HUnlock( to );
}