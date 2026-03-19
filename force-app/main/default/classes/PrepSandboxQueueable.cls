public class PrepSandboxQueueable implements Queueable {
    // test w/ NSP_PrepSandboxTest (100%)
    private String methodName;

    public PrepSandboxQueueable(String methodName) {
        this.methodName = methodName;
    }

    public void execute(QueueableContext context) {
        if ( String.isNotBlank( methodName ) ) {
            switch on methodName {
                when 'runManualSteps' {
                    NSP_PrepSandbox.runManualSteps();                    
                }
                when 'runUserImport' {
                    NSP_PrepSandbox.runUserImport();                    
                }
                when 'runManualSteps2' {
                    NSP_PrepSandbox.runManualSteps2();                    
                }
                when 'runE2CAddresses' {
                    NSP_PrepSandbox.runE2CAddresses();                    
                }
                when else {
                    // do nothing
                }
            }
        }
    }
}