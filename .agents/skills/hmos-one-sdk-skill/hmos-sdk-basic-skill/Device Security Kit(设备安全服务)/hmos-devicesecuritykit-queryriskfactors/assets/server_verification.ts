import { hilog } from '@kit.PerformanceAnalysisKit';
import { JWSVerification, JWSPayload } from './jws_verification';

const TAG = "ServerVerification";
const DOMAIN = 0x0000;

export interface RiskFactorDecision {
  factorName: string;
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH';
  recommendation: string;
  action: 'ALLOW' | 'WARN' | 'BLOCK';
}

export class ServerVerification {
  private jwsVerification: JWSVerification;
  
  constructor() {
    this.jwsVerification = new JWSVerification();
  }
  
  async verifyAndAnalyze(jwsString: string, requestNonce: string, expectedAppId: string): Promise<RiskFactorDecision[]> {
    hilog.info(DOMAIN, TAG, 'Starting server-side verification and analysis...');
    
    try {
      const payload = await this.jwsVerification.verifyJWS(jwsString, requestNonce, expectedAppId);
      const factors = this.jwsVerification.parseRiskFactorResult(payload);
      
      const decisions = this.analyzeRiskFactors(factors);
      
      hilog.info(DOMAIN, TAG, 'Analysis completed, %{public}d decisions made', decisions.length);
      this.logDecisions(decisions);
      
      return decisions;
      
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Verification failed: %{public}s', err.message);
      throw err;
    }
  }
  
  analyzeRiskFactors(factors: Map<string, { status: number, result: string }>): RiskFactorDecision[] {
    const decisions: RiskFactorDecision[] = [];
    
    factors.forEach((data, factorName) => {
      if (data.status !== 0) {
        decisions.push({
          factorName: factorName,
          riskLevel: 'MEDIUM',
          recommendation: 'Factor data unavailable, recommend manual verification',
          action: 'WARN'
        });
        return;
      }
      
      const decision = this.evaluateFactor(factorName, data.result);
      decisions.push(decision);
    });
    
    return decisions;
  }
  
  evaluateFactor(factorName: string, result: string): RiskFactorDecision {
    switch (factorName) {
      case 'isVpnStatus':
        if (result === 'true') {
          return {
            factorName,
            riskLevel: 'MEDIUM',
            recommendation: 'VPN connection detected, may affect network security assessment',
            action: 'WARN'
          };
        }
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: 'No VPN connection detected',
          action: 'ALLOW'
        };
        
      case 'isNetProxyStatus':
        if (result === 'true') {
          return {
            factorName,
            riskLevel: 'MEDIUM',
            recommendation: 'Network proxy detected, may affect traffic security',
            action: 'WARN'
          };
        }
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: 'No network proxy detected',
          action: 'ALLOW'
        };
        
      case 'isDeveloperMode':
        if (result === 'true') {
          return {
            factorName,
            riskLevel: 'HIGH',
            recommendation: 'Developer mode enabled, device security may be compromised',
            action: 'WARN'
          };
        }
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: 'Developer mode disabled',
          action: 'ALLOW'
        };
        
      case 'hdcDebugState':
        const debugState = parseInt(result);
        if (debugState > 0) {
          let debugType = '';
          if (debugState & 1) debugType += 'USB ';
          if (debugState & 2) debugType += 'WiFi ';
          
          return {
            factorName,
            riskLevel: 'HIGH',
            recommendation: `HDC debugging enabled (${debugType.trim()}), device security compromised`,
            action: 'WARN'
          };
        }
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: 'HDC debugging disabled',
          action: 'ALLOW'
        };
        
      case 'odidResetCnt':
        const resetCount = parseInt(result);
        if (resetCount > 5) {
          return {
            factorName,
            riskLevel: 'MEDIUM',
            recommendation: `High ODID reset count (${resetCount}), potential device fingerprint evasion`,
            action: 'WARN'
          };
        }
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: `ODID reset count normal (${resetCount})`,
          action: 'ALLOW'
        };
        
      case 'isDisplayCaptured':
        if (result === 'true') {
          return {
            factorName,
            riskLevel: 'MEDIUM',
            recommendation: 'Screen being captured (recording/streaming), privacy risk',
            action: 'WARN'
          };
        }
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: 'No screen capture detected',
          action: 'ALLOW'
        };
        
      case 'simCnt':
        const simCount = parseInt(result);
        if (simCount === 0) {
          return {
            factorName,
            riskLevel: 'LOW',
            recommendation: 'No SIM card inserted',
            action: 'ALLOW'
          };
        }
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: `${simCount} SIM card(s) inserted`,
          action: 'ALLOW'
        };
        
      case 'globalWindowState':
        const windowState = parseInt(result);
        let windowTypes: string[] = [];
        if (windowState & 1) windowTypes.push('Fullscreen');
        if (windowState & 2) windowTypes.push('Split');
        if (windowState & 4) windowTypes.push('Float');
        if (windowState & 8) windowTypes.push('PIP');
        
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: `Window mode: ${windowTypes.join(', ') || 'Unknown'}`,
          action: 'ALLOW'
        };
        
      case 'batteryChargeState':
        const chargeState = parseInt(result);
        const chargeStates = ['NONE', 'ENABLE', 'DISABLE', 'FULL'];
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: `Battery charging state: ${chargeStates[chargeState] || 'Unknown'}`,
          action: 'ALLOW'
        };
        
      case 'batteryHealthState':
        const healthState = parseInt(result);
        const healthStates = ['UNKNOWN', 'GOOD', 'OVERHEAT', 'OVERVOLTAGE', 'COLD', 'DEAD'];
        const healthStr = healthStates[healthState] || 'Unknown';
        
        if (healthState === 2 || healthState === 3 || healthState === 5) {
          return {
            factorName,
            riskLevel: 'MEDIUM',
            recommendation: `Battery health abnormal: ${healthStr}, potential hardware issue`,
            action: 'WARN'
          };
        }
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: `Battery health: ${healthStr}`,
          action: 'ALLOW'
        };
        
      case 'onCallState':
        const callState = parseInt(result);
        const callStates = ['Not calling', 'Voice call', 'Video call'];
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: `Call state: ${callStates[callState] || 'Unknown'}`,
          action: 'ALLOW'
        };
        
      default:
        return {
          factorName,
          riskLevel: 'LOW',
          recommendation: `Unknown factor: ${factorName} = ${result}`,
          action: 'ALLOW'
        };
    }
  }
  
  logDecisions(decisions: RiskFactorDecision[]): void {
    decisions.forEach(decision => {
      hilog.info(DOMAIN, TAG, 'Factor: %{public}s, Risk: %{public}s, Action: %{public}s', 
                decision.factorName, decision.riskLevel, decision.action);
      hilog.info(DOMAIN, TAG, 'Recommendation: %{public}s', decision.recommendation);
    });
    
    const highRisks = decisions.filter(d => d.riskLevel === 'HIGH');
    const mediumRisks = decisions.filter(d => d.riskLevel === 'MEDIUM');
    const lowRisks = decisions.filter(d => d.riskLevel === 'LOW');
    
    hilog.info(DOMAIN, TAG, 'Summary: %{public}d HIGH, %{public}d MEDIUM, %{public}d LOW risk factors', 
              highRisks.length, mediumRisks.length, lowRisks.length);
    
    if (highRisks.length > 0) {
      hilog.warn(DOMAIN, TAG, 'HIGH risk factors detected, recommend strict security measures');
    }
    
    if (mediumRisks.length > 2) {
      hilog.warn(DOMAIN, TAG, 'Multiple MEDIUM risk factors, recommend enhanced security measures');
    }
  }
  
  getOverallRiskLevel(decisions: RiskFactorDecision[]): 'LOW' | 'MEDIUM' | 'HIGH' {
    const hasHigh = decisions.some(d => d.riskLevel === 'HIGH');
    const mediumCount = decisions.filter(d => d.riskLevel === 'MEDIUM').length;
    
    if (hasHigh) {
      return 'HIGH';
    }
    
    if (mediumCount > 2) {
      return 'HIGH';
    }
    
    if (mediumCount > 0) {
      return 'MEDIUM';
    }
    
    return 'LOW';
  }
  
  getOverallAction(decisions: RiskFactorDecision[]): 'ALLOW' | 'WARN' | 'BLOCK' {
    const overallRisk = this.getOverallRiskLevel(decisions);
    
    switch (overallRisk) {
      case 'HIGH':
        return 'BLOCK';
      case 'MEDIUM':
        return 'WARN';
      case 'LOW':
        return 'ALLOW';
    }
  }
}

export async function serverVerifyExample(jwsResult: string, nonce: string, appId: string): Promise<void> {
  const server = new ServerVerification();
  
  try {
    const decisions = await server.verifyAndAnalyze(jwsResult, nonce, appId);
    
    const overallRisk = server.getOverallRiskLevel(decisions);
    const overallAction = server.getOverallAction(decisions);
    
    hilog.info(DOMAIN, TAG, 'Overall risk level: %{public}s', overallRisk);
    hilog.info(DOMAIN, TAG, 'Overall action: %{public}s', overallAction);
    
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'Server verification failed: %{public}s', err.message);
  }
}