package run

import (
	"testing"
)

func TestCapture_Echo(t *testing.T) {
	result := Capture("echo hello")
	if result != "hello" {
		t.Errorf("Capture('echo hello') = %q, want %q", result, "hello")
	}
}

func TestCapture_WithFormatArgs(t *testing.T) {
	result := Capture("echo %s", "world")
	if result != "world" {
		t.Errorf("Capture('echo %%s', 'world') = %q, want %q", result, "world")
	}
}

func TestCapture_TrimOutput(t *testing.T) {
	result := Capture("echo '  spaced  '")
	if result != "spaced" {
		t.Errorf("Capture trimmed output = %q, want %q", result, "spaced")
	}
}

func TestCapture_FailedCommand(_ *testing.T) {
	// Should not panic on a failing command
	_ = Capture("false")
}

func TestSilent_Success(t *testing.T) {
	if err := Silent("true"); err != nil {
		t.Errorf("Silent('true') returned error: %s", err)
	}
}

func TestSilent_Failure(t *testing.T) {
	if err := Silent("false"); err == nil {
		t.Error("Silent('false') returned nil, want error")
	}
}

func TestVerbose_Success(t *testing.T) {
	if err := Verbose("true"); err != nil {
		t.Errorf("Verbose('true') returned error: %s", err)
	}
}

func TestVerbose_Failure(t *testing.T) {
	if err := Verbose("false"); err == nil {
		t.Error("Verbose('false') returned nil, want error")
	}
}

func TestExecute_Success(t *testing.T) {
	if err := Execute("true"); err != nil {
		t.Errorf("Execute('true') returned error: %s", err)
	}
}

func TestExecute_Failure(t *testing.T) {
	if err := Execute("false"); err == nil {
		t.Error("Execute('false') returned nil, want error")
	}
}

func TestOSA_NoPanic(_ *testing.T) {
	// OSA wraps Capture with osascript - just verify no panic
	_ = OSA("return 1")
}
