#!/bin/bash

# just some helper commands to aid
# in developing the features for 20.12

orchestrator=http://localhost:9015/v2
clm=http://localhost:9061/v2
emcoroot=~/EMCO

# create a project compatible with emco.sh
projectname="test-project"
projectdata="$(cat<<EOF
{
  "metadata": {
    "name": "$projectname",
    "description": "description of $projectname controller",
    "userData1": "$projectname user data 1",
    "userData2": "$projectname user data 2"
  }
}
EOF
)"
curl -X POST "$orchestrator/projects" -d "$projectdata"

# create my two DCM clusters compatible with dcm_call_api.sh but not with emco.sh
cpdata="$(cat<<EOF
{
    "metadata": {
        "name": "cp",
        "description": "",
        "userData1": "",
        "userData2": ""
    }
}
EOF
)"
c1data="$(cat<<EOF
{"metadata": {"name":"c1","description":"<string>","userData1":"<string>","userData2":"<string>"}}
EOF
)"
c3data="$(cat<<EOF
{"metadata": {"name":"c3","description":"<string>","userData1":"<string>","userData2":"<string>"}}
EOF
)"
cat > c1.config<<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJd01EY3dNakl4TXpjeE0xb1hEVE13TURZek1ESXhNemN4TTFvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBUEZVCkVwZWMxSmRSSFlUYko1dHEwemM5aEpxR2l2QnlvUXlxZFJ2YjVQK2dCeG9VL01RMHhnSDhrbFA5Ykp5VitxZUsKYUI0S2lkSk1HYWdUV2FhdUpCYlFHYmdnaldGSzR3U3pXakExM0RCQ2xSRWlLVG5MSnkvK3gzK0lOODIrY2MvUApNTWhkSUE2aW9NMjRpa2JkQ3RobkRSVWNUNU4wdDBVaGxMc1p3cWM2bXhJTVcxSGM0ckpsRmY3UVpCbmh3N0lLCjIzRlREcWJ5Ykw2Y1Q2OHFOdEg3RFJaNURUV3lzOTJMR0NCcXlPUW9kZS9TQVFHcGpBRkt0L1FDM2lXUW43RXkKbkxSZjBIOWR6MEJVUUhaQUhMd21IVkdUdFJ5ZWMyMU5uQzZHcUsralY4d1BCcXR1Q2xWUGdOT0xLNTJxSkd5VgpqSE5DckR6TWVpRHR3dTMzL1VVQ0F3RUFBYU1qTUNFd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGRXJScFpGMnk4dDcxQkJCOXN4cC9kbGMwY3gKblVZRSt2alFnT2FrTUltVHcrTkEyR2l0a2NtNUtNeDBwQzNKUmg5MW1sYTFOZ28xZHcwRkE1ZE5BZW5Ua1lmSgpiVXhqM0gzZXhVSmtFekgxbSs4dTk3d0ZzVTNkZ3d6VWNQRkFUcmlVeEZvdjA0b1NzSUExa3ZLb1ZkaThlUnBKCjJXN1Y4bzNpdVFTR1lXZHNMcDhTbWJwazlhQS9qK2d4TXpNOFBpN1loQUpSM0lOcURsaU1CbnJaVTRzaU5LRTUKTDhNRVV5Y1dRbmNHTDJUbUZDU25vN1ZjTmtlTWdudFZpbGtoaUpjOEdNV1VzakVkSmNxbm9SOGs1ODdjTXBJZQorcm9kMlhsRTBmakZRRG9FSnRhYXlZQjNEWFRBSU4vMWNkRjE1bWdCN0Y3R2tnNGNPM0lPSmxZQXBEMD0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    server: https://192.168.121.203:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM4akNDQWRxZ0F3SUJBZ0lJVDlyb0xXdEptOWt3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TURBM01ESXlNVE0zTVROYUZ3MHlNVEEzTURJeU1UTTRNVFZhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXhiQUE2am9pTkJIMzZrSUoKOVVEVEt3Rmc1U2RrVW1pdnozNXpmVVNFUlhKZVdEdHdKK0pvY0lIdGlGTEtpdnNCZENmdzVsbm8rbzBJaEc3VwpLU0FIcXFlT0tRQVZISnZHSFoyM0MrSFhwK3NGNFU4cmNZcXRkK3FPbXE0bk5zRFE2bVA5am9QSDdBNWhtbE15CnFOMCtnNUh0QXhRM05ILzRvdGlCYlpjNUk4THVRRGpQdFpFSDVLQVY5TTRicXFxSTlHV3I4T0xUdG5tWVRQQWwKZHBWaVpUYS91WFRrOUJOQzRZanR0ZGRJVThvOFdFbDhsMGFkRXcwalVFQWlJa3Z6M2pqbnpZams1RmtXUnlKcwplVlBMaDZ1d1VPaW5xU0NFdHU1a1RVdTFNU0IrdW9la2piMG1zaDZEbGxZM1dMM2E1ZHpsNFdKb0FheGIxOU5FCkxnYzZ6d0lEQVFBQm95Y3dKVEFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFEbVBrSm9uc00raGJ3WHI1ZXMvQ0VXUnNmYnhWQjAvV2k2NwpmZUxIMEpQZWJyUE5pakJjM0VJT1EyVnVmaTBoU2l2Sjc2bnl4SzBoVlpWdzVEYVV3d0xhelFMNkI5Y1Q5RzBuCjUvem0xOWtUVlhlVkVHUitaTUJhR216NjMwdEV0clgzVFROdjJXYUo2bzNHZGtxU0ZsSyt6SEZ0a0ZvMEV3Zm0KQ0w4ZjZJck9PWDNPVDlXSmlLUXBGYnZLa3Z0clkxTG1BczZCY0hBM25UL0RJeXdMRHNxWjhBQmNDc0dGZnB5NwovV083OUs0cWYxUnZDSEpwc2RtMHRac0JFYjZOR0lNUXRkRkw3V1llc25CdFRJUzdMdGxIdnY0U2JjYVBjd0hBCkJQWlVHNit1UW9JZktBK1hkQldGOHJuSE9tWk4rUG8yS3ZNbkFhc1p1YlVhUWI0MGdvQT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBeGJBQTZqb2lOQkgzNmtJSjlVRFRLd0ZnNVNka1VtaXZ6MzV6ZlVTRVJYSmVXRHR3CkorSm9jSUh0aUZMS2l2c0JkQ2Z3NWxubytvMEloRzdXS1NBSHFxZU9LUUFWSEp2R0haMjNDK0hYcCtzRjRVOHIKY1lxdGQrcU9tcTRuTnNEUTZtUDlqb1BIN0E1aG1sTXlxTjArZzVIdEF4UTNOSC80b3RpQmJaYzVJOEx1UURqUAp0WkVINUtBVjlNNGJxcXFJOUdXcjhPTFR0bm1ZVFBBbGRwVmlaVGEvdVhUazlCTkM0WWp0dGRkSVU4bzhXRWw4CmwwYWRFdzBqVUVBaUlrdnozampuellqazVGa1dSeUpzZVZQTGg2dXdVT2lucVNDRXR1NWtUVXUxTVNCK3VvZWsKamIwbXNoNkRsbFkzV0wzYTVkemw0V0pvQWF4YjE5TkVMZ2M2endJREFRQUJBb0lCQUNySTlPbTh1enBaeVRaQwpKTFdYMmh3c3FEUHdXcDRiV2pHbVJJaVFFN0NVR0Njd2RnMnJ5cjdPNEFIcEtUejdKazFsZDVYalQ3RXFaUFdFCnA0VXZFWG0xMmVhMXhkdnpPdVdlQk1mbGtTOGVocDlFNnpvZnNYdUtvR0tKM3FMVENHUXlUK1pRVHl5ZjBDLysKWWJCNmNkVTM5L3Y2bkJnWXVrOUVYSDdEZy9KaEZKWkkyRmlYSHRtUk5qSkQ1R2FmQlUwOGxKNzlYMFExaDAySgpRQlNhdlgvQzBYc3d5U1duNFk4SEx0Z0VJWW1GOTE0Rm0vRHlKUGtsRVBuL1lOS0ZTMGVTaGczbjM3UFJEaXcwCit5eVoreTVLZjZDZ3l2YWdLWDIvRmpHdjdtclJhcTVyU21YNnZzK01TUi9NVFFQR1pMOHh6V0pJMkIrSE16bDcKWGF6U1RrRUNnWUVBNXZLbUxXeHl3Wk1xM1J5Q25KQmc4SVo1dVBMVlFNbWZ1cnYrS0VFU3FOYjFhUEVUMTJBKwozWlphMGI4bXFtb3A2ajMyMFN1UHM0UXVYQVVic3dpN201QkNXb3kzUi9CUnVDdTBsVXgyYWJrOVJ1ZStnemRxCkh6YVQvS1Y3aDcwdXVXUThBKzZESkUrejI1ZTZmNlpyNnFiRHdzdU5OcGNxQnZPaDlTQklWRlVDZ1lFQTJ5RzUKcExiYzRJTWdVMzV5cGxTejhFanNvem5MTDlpeHpuNlpGczN1K2xjODF5Mzh4UHA0bEQxT002aGd2Z0pUV0ljKwovMVlYUWJoRjFWRHBWQkNsVWljRW1hbXVrZW5EZUNWNnM4V0l4a3VvV1ZQSm9GYnh2T1RXTi81VjRRV2lqQVNiCnYzK0RSYUM4Z3hvV3BqbG40RU5QeHdsTmtiZFY5RzJIOVBQQmxwTUNnWUVBejZNVmVQMXA1MVFUVTV5UWFZYjkKUVFNR2FSd2FVeGR6Zm9ZS3FkSm5ubGsxWjFab0NsbkQ2NkdFb2RPRVJlOFJKRUwxcDNYTXl3OXFSdDFvMi94YwpBQzhoR1J3dXBJVVNVODBubkp1VVV0VnluRTg2Mytwd2hRT2k1YUU2Z1AyOEJuNXgzdThRQlJPTGwwREJNb2RECnUwS1grb2pidTFzSk5CclRYL25ZVGNrQ2dZRUFpRUdsUEwyVUJHcWt2Q1loUmpuZkZXZFM5WC9uVHg0UUdkVncKZmRTWlo4SzlDeFFHVzdsZkp0WWovVTBTc3JPaGZhZkRUV1FMM0Fxb0thZEJIc3VtOExsZ1MraE5xMTlPOHpOaQo0OHZOYTNmNSsybDFNeVU4OVhiWm1VR2x4dUVKSE1WMHp4T0wzY3kveTBsNmtldWFJc0hZSm13cmRwTW9lRzl2CkhhcEFVczhDZ1lBTkN2Q1hrMy9wcFNYZytYVlhxWEhucVZzeWtGeEt0Sm8ydE1Ta1l3NEVJVmZpQnBUU2YyZXgKekl1RHVYYXgxOUNsYndUNXQ2TUtRWGVaUWhGQmVtSmxoNW1hV2p6d0xiUi9IY3VKNkNRNzlYTTd4MEtJakdqbQpYUDFRWW5pOHpSUzRmeVA5OTNrTy9FNDJKU0RMSUVlZ21wODNqN0hxMUtSeitUam82TUxaWGc9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
EOF
cat > c3.config<<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJd01EY3lPREl6TXpBMU5Wb1hEVE13TURjeU5qSXpNekExTlZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTGliCmRmM3NERkljcUtFdGtSWU5mZ3lFZGpqeFFteDhqQ1M0ekRqNVE4d3gyYjlQSjNmc0dhUnpmVEI1ZENxRy9PeUoKMHROQVpsUFYwOVMxbkU4Vmd4dmF5bWtkNHVON2Q1Rk85RUdhL0pWRnl1RlFuRHRTRWs4LzBiWGhGc1VMWG1Ccwp6QUZiRjNGRlZwVDhpZVlqbG8wcWtNUkE3bUMzT0dpVDJ5NVZmNFFsTDE2bDdBZHlJMWdKUndsZUVGa1BFd2NWClBWSWVON0JyQ3NTWS9NYTUvZW1EekpqbzFXYVRya3c2cDhBTWxrT0c4Y2ZzMTU4Z0RvNWtRK3dkRitSdkY1SWIKVXFla2hSb3NwUUF2Zi9LM0hiQ0ZHa3h3em91NStXQUk0aEpEL0F2TDRrcUMyVzRucExhNG16c2hhcFp1cHE1RApMSnUvSFlKM242aTcrV0doNk1VQ0F3RUFBYU1qTUNFd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFIZk9penFPV1F6UVVrc3ZSeWY3YysvT1FiS00KNmU1NHVWUFMrMklDWXhIRDQ2K3Z1U1VJbXpPTXJxWjZJN2trdm9CUis5eDJlMFVncmZLSUR1aWJURCtLelViSAo1SFFrc0RtZzRLaDhWbXZmaXJFS2xHYXRMcDhWL2VPaHpJQlFJRHVVYmdjcWY5Z3YxeFdsOFpMOFZRdlZYQXJnCnVhN3MzMkxJeWlKbXhTbU1rTzk3aU9Qbk1MSkNpcE9NQUNEUS9EUVZ2TGtUTEg5L04yZ09BVXFvajJaZ3ArdGIKK3ZCZ1ZOVmZKNE5UbHE2SGY0eldNOVR2cGM1N0Q2ay8yeVFleU9yd2UrZkVKcUQxMXltK2Fib0NoazZYMm1mbwpXdDRrc3RQSis4ZzJpaTdhOVNpU0xpN2g2eFdRWUhUWk8yTDEvK084MEFJeE9KZW1kN0lBZnMvVHRyVT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    server: https://192.168.121.149:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM4akNDQWRxZ0F3SUJBZ0lJS0NIMExGZWtjY2t3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TURBM01qZ3lNek13TlRWYUZ3MHlNVEEzTWpneU16TXhOVGxhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXR4aXFjWDFSdWJUZzAyOGQKaGJja1dZM0NoMFY5Y3FVRmtiS1NpazhFUEFOd1dkd2k1ZkMySU53N1ovcnJPZmU0RVlxVE11dE42dVZlMmJGegorbmZEemltM0FIVHJLV1FCajMrKzEzcjVMUTV2VnlaNnVYSndoSUxncE9lUDBBbGdZVXl5OFBXQ1hQVDE3T2hECk45YmkyVVp1Q1NxSW4rSXlwMXRPb0w2U3J1dDd2RmdVbzdrd29qY1p0cDJrTTJQdU51ejFqZU16WDlZQ25IVnEKUURJM0Zsd0RJNUNuOGs0Nzc3S0xsRXlwOFJDYVJvYnlRME8vaVhIMGJpUlNBazY5ZWJVMW1Eem5WekU4Sm42aQpaR21KM0ZqS21YYVh6S21HUTNBRm81L2RpckNNTGFhL0JTOWprOERZczU1OFQydUNDYXFRcTVTOVAycHBHWlNXCmh4eEdMd0lEQVFBQm95Y3dKVEFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFGRWZKdDdvNXp6Vzlxem55V2Z6UkZoS1RHK282UzlrUUV5dwpOaVIrS1BQcnF5U0tFY2VCL1AwS0gwbU1IdmxQTEFBbFNlZ1dvVmVJSTJvcitQbXhuUzl6anpWcnR2YjdCclRXCkdYc2w4OExoWDBSSFlRZ0hOTWIyWDNSMmhIRXNkSUNjd05lVzZpdFlHOGV2MHZPMENPNUJjL2dYeFI2MnhaRDcKRzgyb3NsNTI2NE83WFdxMUhmRzc5QVJWTmFxRzFQSTgyR0ovVDc0TDAraDV6am9qQmZoUDQ5VVUrMEQ5QXhrOQpTeFgzOFhpMElBMlRydVZqTE5IY2syTE5KbXpGZE5WVG5nRVhTT0lFR1ZrcStpNEJwOHFTbFZObFJuQzlNOVhNCnZIbTAvdGxRdUNCTlROYjI3SStiRVM2eEU3NjBHSWF5WWZxWk1QQkhHZzU2Nm04L0sxRT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcFFJQkFBS0NBUUVBdHhpcWNYMVJ1YlRnMDI4ZGhiY2tXWTNDaDBWOWNxVUZrYktTaWs4RVBBTndXZHdpCjVmQzJJTnc3Wi9yck9mZTRFWXFUTXV0TjZ1VmUyYkZ6K25mRHppbTNBSFRyS1dRQmozKysxM3I1TFE1dlZ5WjYKdVhKd2hJTGdwT2VQMEFsZ1lVeXk4UFdDWFBUMTdPaEROOWJpMlVadUNTcUluK0l5cDF0T29MNlNydXQ3dkZnVQpvN2t3b2pjWnRwMmtNMlB1TnV6MWplTXpYOVlDbkhWcVFESTNGbHdESTVDbjhrNDc3N0tMbEV5cDhSQ2FSb2J5ClEwTy9pWEgwYmlSU0FrNjllYlUxbUR6blZ6RThKbjZpWkdtSjNGakttWGFYekttR1EzQUZvNS9kaXJDTUxhYS8KQlM5ams4RFlzNTU4VDJ1Q0NhcVFxNVM5UDJwcEdaU1doeHhHTHdJREFRQUJBb0lCQVFDMENNdm5wZnNMS0lEOQpSYi80c0RsTTJXaFN6SkJxZnpzM3BTZ1VXVmZuanRZVmRiRFcrbGFMZnlIbXYwSTJrSTdzcUo3T3JiTEM2dURXCkczZlg2NVdjRFVhRmEzR2tGRks0Z0RydDlGdzQ0bjIyYXY2M2hJQ0F1NVFhY2hybHk2SjZhZ2wxaDJLMDlxVXUKV3I5bGs2VWhVZkIya04wZ29URi9mL2VUZFhBVUQ0d0l0VHVSaVc4K2YyaEI5RUsxSTNrVzBkZ2pIM0FLTXY1VApkRjFqL3hsbVdLaU9xODFGVEgzY1BnK0VSY3RpcHUrdUd2cCtLMUYrSThZbks1V2Y3WG9JZXhuYnhwb0ZmYURHCmEyR1J2ZzR0QlB6SFIwbDNlczZ6NG1LVU1qTkpkN21qS25zdTBSdjZiUGJKUFZ0TkxkUTU1MVN3VzA4QVk0WXYKSW1FUlhTK3hBb0dCQU0wSXI1VWxmSFlibTdBeDUzMm41eStVZ1ZJL0hwVmljL0M2TXFZS1RGL3hIS3NodjhVLwpvUDhkenFiaEVyeXQ1VnVLcklSLzN1SkIyMVd1bExyVVovaTRDNzFFZERJSDZlRWE5YWwvUjVMemEyWjAwT0k2Ci9xbmlqR1FweEpra0RGRDBQNUQ4SStKNzBuUTM0bXZDSzk1NytWbkdtRDdGa0Y2Q1NKalFpekczQW9HQkFPU2IKKy9oQkFNNXYxMkpJWnFuajVibHc2ZktmRFhKWUR1S01WNUpiUzA3Q2JwNVFOZGlaWVVXN1JqeVcweUhxOHBINwo1cm5EVXNBamUreERLOHVHU2JvVEEwMDZqMXN5djZ4cmpvaXlHQWQreTBKWjF5dGgwL1greE5sWlF4SHJDb200ClE3RGpjMmk4TlIzSUhhRlUvTnlFbmRacnBYdnlWZDJvY2NZZkNhOUpBb0dCQUxhakNCU3BJYWJyak5GMGdxcHgKeUFPZ0cxb3lFNElxQXZEcVMzZVFNTnc5b0xYb0NEVWlLcjFWeGVEdEdJMnRzV0xMc2tVTXluTnRDbjNXVjNIZApCd2lNbVJodFE3dlZSTVphQjM2R2ZERXdWL2thRVgrVDRZbGUzb1BTbU9kNUx1ZGx5c0hSZC8ybElxQ1hyejhoCjVZWDNsUFFkYlR4dEs5NmoyeHNVbVFrZEFvR0FKaEJTdytNTzMxQi83RDFoMnFlM2VFajBxeEVRakJsZFlSczgKK1lGNTZJTTNKK1R6RWoxM2xNUzV6UnpQeXJYejdacWpzQXAxbk1oTHVlcjFQODM4T0o4eHpZb1NsSHkrclZhNwpSTWRpZU4wRHV1aDZpeDZlekRhL1QvRXMyYTdvOGtWYi8vZmZIM0UyNXQ2TEVIRzJLSUZzUm1kbUJsMHpMdFQ5CkhKL09YUUVDZ1lFQW1mYzFseTRVQzZlS00yNmp2RGZkWldTNTFSeVFyUHZoVURsS09lR3QzdFdaZ3hxL0hhdDAKUjZYRHNUd09kTTg5UVJCWThwOVF2UWNJMGYyMHp1RDNoMEsrbkJvakJMS0hmNnBiWlNMZW1NTjRsWWtINW83MQo1aVdvWkFXL1gwR2QxdE5DNEVSNTM4Ky9XSWgwUlJ2MXNWdkxqZ09Td0g4NkpFUGltUFdkaVdZPQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
EOF
labelname="LocalLabel"
labeldata="$(cat<<EOF
{"label-name": "$labelname"}
EOF
)"
curl -X POST "$clm/cluster-providers" -d "$cpdata"
curl -H "Content-Type: multipart/form-data" -X POST "$clm/cluster-providers/cp/clusters" -F "metadata=$c1data" -F "file=@c1.config"
curl -H "Content-Type: multipart/form-data" -X POST "$clm/cluster-providers/cp/clusters" -F "metadata=$c3data" -F "file=@c3.config"
curl -X POST "$clm/cluster-providers/cp/clusters/c1/labels" -d "${labeldata}"
curl -X POST "$clm/cluster-providers/cp/clusters/c3/labels" -d "${labeldata}"


# create a generic placement intent
generic_placement_intent_name="test-generic-placement-intent"
generic_placement_intent_data="$(cat <<EOF
{
   "metadata":{
      "name":"${generic_placement_intent_name}",
      "description":"${generic_placement_intent_name}",
      "userData1":"${generic_placement_intent_name}",
      "userData2":"${generic_placement_intent_name}"
   }
}
EOF
)"
curl -X POST "${orchestrator}/projects/${projectname}/composite-apps/CollectionCompositeApp/v1/deployment-intent-groups/collection_deployment_intent_group/generic-placement-intents" -d "${generic_placement_intent_data}"

# get the generic placement intent (to verify)
curl -X GET "${orchestrator}/projects/${projectname}/composite-apps/CollectionCompositeApp/v1/deployment-intent-groups/collection_deployment_intent_group/generic-placement-intents/${generic_placement_intent_name}"

# delete the generic placement intent
curl -X DELETE "${orchestrator}/projects/${projectname}/composite-apps/CollectionCompositeApp/v1/deployment-intent-groups/collection_deployment_intent_group/generic-placement-intents/${generic_placement_intent_name}"

# instantiate vs. terminate
cd $emcoroot/kud/tests
./emco.sh instantiate
./emco.sh terminate
